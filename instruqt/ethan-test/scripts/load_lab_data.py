#!/usr/bin/env python3
"""
load_lab_data.py — load the class's captured dataset into Graylog at lab launch.

Ingestion path: **bulk-index straight into the typed Illuminate index sets**
(Path A). The earlier GELF approach was abandoned: GELF additional fields must be
scalars, so multi-valued enrichment fields (e.g. gim_event_type_code, an `integer`
in the Illuminate mapping) got flattened to JSON strings like "[\"120000\"]" and
were rejected by the strict mapping — every rich doc landed in gl-failures.
Bulk-indexing the cooked docs verbatim (native JSON arrays) preserves arrays AND
field types, which later modules depend on.

Two backend shapes are supported (auto-detected):
  * **Framework / Instruqt** (the real target): Graylog 6.x/7.x in Docker against a
    plain OpenSearch with the security plugin DISABLED — `http://opensearch:9200`,
    no auth, no TLS. This is the default.
  * **Datanode** (e.g. a local Graylog 7.x datanode sandbox): OpenSearch behind the
    datanode requires a JWT over HTTPS. Enabled automatically when GL_PASSWORD_SECRET
    is set (or AUTH_MODE=jwt). The HS256 signing key is the password_secret bytes
    repeated/truncated to 64 bytes (Graylog's scheme).

How it works:
  1. Resolve each event_source_product -> (stream_id, index write alias) from the
     live Graylog API (streams by title -> index_set -> index_prefix).
  2. Re-stamp every doc's timestamp to launch time (uniform delta; relative spacing
     preserved). Strip internal fields (_id, gl2_*). Set the doc's `streams` field
     to the destination stream id (this is what makes a directly-indexed doc appear
     under that stream in the Graylog UI — bulk writes bypass stream *rules*).
  3. Bulk POST to OpenSearch (`<prefix>_deflector` write alias).

Runtime config via env:
    GL_API_URL          default http://localhost:9000   (Graylog REST API; set to
                        https://localhost after the Framework HTTPS flip)
    GL_API_USER         default admin
    GL_API_PASS         default 'yabba dabba doo'
    OS_URL              default http://localhost:9200    (OpenSearch / datanode)
    AUTH_MODE           auto|none|jwt  (default auto: jwt iff GL_PASSWORD_SECRET set)
    GL_PASSWORD_SECRET  only needed for the datanode/JWT backend
    TLS_VERIFY          default 0 (self-signed certs in lab) — applies to any https URL
    LOG_DATA_DIR        default <this script>/../log_data
    LAUNCH              default 'now' (ISO8601 to override)
    BATCH               default 1000  (docs per _bulk request)
"""
import os, sys, json, glob, time, base64, hmac, hashlib, ssl
import urllib.request, urllib.error
import datetime as dt

API     = os.environ.get("GL_API_URL", "http://localhost:9000").rstrip("/")
USER    = os.environ.get("GL_API_USER", "admin")
PASS    = os.environ.get("GL_API_PASS", "yabba dabba doo")
SECRET  = os.environ.get("GL_PASSWORD_SECRET", "")
OS_URL  = os.environ.get("OS_URL", "http://localhost:9200").rstrip("/")
VERIFY  = os.environ.get("TLS_VERIFY", "0") not in ("0", "", "false", "False")
HERE    = os.path.dirname(os.path.abspath(__file__))
DATA    = os.environ.get("LOG_DATA_DIR", os.path.join(HERE, "..", "log_data"))
LAUNCH  = os.environ.get("LAUNCH", "now")
BATCH   = int(os.environ.get("BATCH", "1000"))
# Illuminate installs its named source streams asynchronously; wait up to this many
# seconds for them before falling back to auto-creating our own. 0 disables the wait.
ILLUMINATE_WAIT = int(os.environ.get("ILLUMINATE_WAIT", "180"))

# Auth mode for the OpenSearch bulk endpoint. "auto": use a JWT only when a
# password_secret is supplied (datanode backend); otherwise no auth (Framework's
# security-disabled OpenSearch).
AUTH_MODE = os.environ.get("AUTH_MODE", "auto").lower()
USE_JWT   = AUTH_MODE == "jwt" or (AUTH_MODE == "auto" and bool(SECRET))

# Curriculum mapping: a cooked doc's event_source_product -> the Illuminate stream
# it belongs to (resolved to id + index set at runtime, by title).
STREAM_TITLE_BY_PRODUCT = {
    "windows_sysmon": "Illuminate:Sysmon;Messages",
    "windows":        "Illuminate:Windows Security Event Log Messages",
    "powershell":     "Illuminate:Powershell Messages",
    "suricata":       "Illuminate:Suricata Messages",
}
DEFAULT_STREAM_ID = "000000000000000000000001"
DEFAULT_PREFIX    = "graylog"

# Cosmetic "Received by": stamp bulk-indexed docs with this input's id (+ the node id)
# so they display as if they arrived through the Global GELF input. The data is still
# bulk-indexed — real input-flow is deferred to the module that needs it. Must match
# provision_input.py's TITLE. Set RECEIVED_BY_INPUT="" to disable stamping.
RECEIVED_BY_INPUT = os.environ.get("RECEIVED_BY_INPUT", "Global GELF")

STRIP_PREFIX = ("gl2_",)
STRIP_EXACT  = {"_id", "streams", "timestamp"}

# Fields that the Illuminate/GIM mapping types as `long` but the cooked archive
# carries as hex strings (e.g. "0xd24"). Coerce hex -> int so the bulk index does
# not reject them (~7% of docs were dropped otherwise). Only these exact fields —
# other hex-looking values (e.g. Windows logon_id) are legitimately kept as strings.
HEX_INT_FIELDS = {"process_id", "process_parent_id"}


def log(m): print(f"[load_lab_data] {m}", flush=True)


def unverified_ctx():
    """SSL context that skips verification (lab self-signed certs)."""
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def _ctx_for(url):
    """Return an SSL context for https URLs (None for http)."""
    if not url.startswith("https"):
        return None
    return ssl.create_default_context() if VERIFY else unverified_ctx()


# ---- Graylog REST API (basic auth) ----------------------------------------
def _auth_hdr():
    return "Basic " + base64.b64encode(f"{USER}:{PASS}".encode()).decode()


def api(path):
    r = urllib.request.Request(API + path, headers={
        "Authorization": _auth_hdr(), "Accept": "application/json",
        "X-Requested-By": "lab-loader"})
    raw = urllib.request.urlopen(r, timeout=20, context=_ctx_for(API)).read().decode()
    return json.loads(raw) if raw.strip() else {}


def api_post(path, body=None):
    data = json.dumps(body).encode() if body is not None else b""
    r = urllib.request.Request(API + path, data=data, method="POST", headers={
        "Authorization": _auth_hdr(), "Accept": "application/json",
        "Content-Type": "application/json", "X-Requested-By": "lab-loader"})
    raw = urllib.request.urlopen(r, timeout=20, context=_ctx_for(API)).read().decode()
    return json.loads(raw) if raw.strip() else {}


def wait_for_graylog():
    for _ in range(60):
        try:
            urllib.request.urlopen(API + "/api/system/lbstatus", timeout=5,
                                   context=_ctx_for(API))
            return
        except Exception:
            time.sleep(3)
    sys.exit("Graylog not reachable")


# ---- OpenSearch bulk (optional JWT for the datanode backend) ---------------
def jwt_key():
    b = SECRET.encode()
    return (b * ((64 // len(b)) + 1))[:64]


def mint_jwt(key):
    def b64(d): return base64.urlsafe_b64encode(d).rstrip(b"=")
    now = int(time.time())
    header = b64(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    payload = b64(json.dumps({"sub": "admin", "os_roles": "admin",
                              "iat": now, "exp": now + 300}).encode())
    signing_input = header + b"." + payload
    sig = b64(hmac.new(key, signing_input, hashlib.sha256).digest())
    return (signing_input + b"." + sig).decode()


def bulk(ndjson_bytes, key, ctx):
    r = urllib.request.Request(OS_URL + "/_bulk?refresh=false", data=ndjson_bytes,
                               method="POST")
    if USE_JWT:
        r.add_header("Authorization", "Bearer " + mint_jwt(key))
    r.add_header("Content-Type", "application/x-ndjson")
    try:
        resp = urllib.request.urlopen(r, context=ctx, timeout=120)
        d = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"bulk HTTP {e.code}: {e.read().decode()[:300]}")
    errs = 0
    if d.get("errors"):
        for it in d.get("items", []):
            if it["index"].get("error"):
                errs += 1
                if errs <= 3:
                    log(f"  bulk item error: {it['index']['error'].get('reason','')[:160]}")
    return len(d.get("items", [])), errs


# ---- transform ------------------------------------------------------------
def parse_ts(s): return dt.datetime.fromisoformat(s.replace("Z", "+00:00"))


def _to_int(v):
    """Coerce a hex ('0xd24') or decimal value to int; return unchanged on failure."""
    if isinstance(v, list):
        return [_to_int(x) for x in v]
    if isinstance(v, str):
        try:
            return int(v, 16) if v.lower().startswith("0x") else int(v)
        except ValueError:
            return v
    return v


def received_by_fields():
    """Resolve the Global GELF input + node ids for the cosmetic 'Received by' stamp.
    Returns {} (no stamp) if disabled or the input is absent."""
    if not RECEIVED_BY_INPUT:
        return {}
    try:
        inputs = {i["title"]: i for i in api("/api/system/inputs").get("inputs", [])}
        inp = inputs.get(RECEIVED_BY_INPUT)
        if not inp:
            log(f"note: input '{RECEIVED_BY_INPUT}' not found — docs get no received-by")
            return {}
        nresp = api("/api/system/cluster/nodes")
        nlist = nresp.get("nodes", nresp)
        if isinstance(nlist, dict):
            node_id = next(iter(nlist), None)
        elif isinstance(nlist, list) and nlist:
            node_id = nlist[0].get("node_id")
        else:
            node_id = None
        fields = {"gl2_source_input": inp["id"]}
        if node_id:
            fields["gl2_source_node"] = node_id
        log(f"received-by: input {inp['id']} node {node_id}")
        return fields
    except Exception as e:
        log(f"note: received-by lookup failed ({str(e)[:80]}) — skipping stamp")
        return {}


def prep(doc, delta, route, received_by):
    """strip internals, restamp, set streams; return (write_alias, doc)."""
    product = doc.get("event_source_product")
    if isinstance(product, list):
        product = product[0] if product else None
    stream_id, alias = route.get(product, (DEFAULT_STREAM_ID, DEFAULT_PREFIX + "_deflector"))
    out = {k: v for k, v in doc.items()
           if k not in STRIP_EXACT and not any(k.startswith(p) for p in STRIP_PREFIX)}
    ts = parse_ts(doc["timestamp"]) + delta
    out["timestamp"] = ts.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
    out["streams"] = [stream_id]
    # Coerce hex-string numeric fields the GIM mapping types as `long` (else dropped).
    for f in HEX_INT_FIELDS:
        if f in out:
            out[f] = _to_int(out[f])
    # Cosmetic "Received by <input> on <node>" (stripped gl2_* re-added intentionally).
    out.update(received_by)
    return alias, out


def default_index_set(index_sets):
    """The writable default index set (id, prefix) — where auto-created streams write."""
    for s in index_sets:
        if s.get("default"):
            return s["id"], s["index_prefix"]
    # fallback: the 'graylog' prefixed set
    for s in index_sets:
        if s["index_prefix"] == DEFAULT_PREFIX:
            return s["id"], s["index_prefix"]
    return index_sets[0]["id"], index_sets[0]["index_prefix"]


def create_stream(title, index_set_id):
    """Create a stream on the given index set and resume it; return its id.

    Bulk-indexed docs carry `streams=[id]`, so the stream only needs to EXIST (and
    be running) for the UI/search to surface them — no stream rules are needed. This
    is our fallback when Illuminate did not provision the named source streams."""
    # GL 7.x wraps the create body ({"entity":..., "share_request":null}); a plain
    # body 400s with "CreateEntityRequest: entity cannot be null".
    entity = {"title": title, "description": "Auto-created by the Academy lab loader.",
              "index_set_id": index_set_id, "remove_matches_from_default_stream": True}
    body = {"entity": entity, "share_request": None}
    sid = api_post("/api/streams", body).get("stream_id")
    if sid:
        try:
            api_post(f"/api/streams/{sid}/resume")
        except Exception as e:
            log(f"  note: could not resume stream '{title}': {str(e)[:80]}")
    return sid


def wait_for_illuminate_streams(titles, timeout):
    """Poll /api/streams until every title exists, or timeout. Returns the last
    {title: stream} snapshot. Illuminate creates these streams asynchronously, so a
    short wait lets us route into the REAL Illuminate streams/index sets (needed by
    later enrichment/asset modules) instead of immediately auto-creating duplicates."""
    titles = list(titles)
    deadline = time.time() + timeout
    snap = {}
    while True:
        snap = {s["title"]: s for s in api("/api/streams")["streams"]}
        missing = [t for t in titles if t not in snap]
        if not missing:
            log(f"Illuminate streams present ({len(titles)}/{len(titles)})")
            return snap
        if time.time() >= deadline:
            log(f"Illuminate wait timed out ({len(titles) - len(missing)}/{len(titles)} "
                f"present after {timeout}s); will auto-create the rest")
            return snap
        log(f"waiting for Illuminate streams… {len(titles) - len(missing)}/{len(titles)}")
        time.sleep(5)


def build_routes():
    """event_source_product -> (stream_id, '<prefix>_deflector').

    Prefer the REAL Illuminate source streams (wait for them, since Illuminate creates
    them asynchronously) so data lands in the typed Illuminate index sets that later
    modules expect. If a stream is still missing after the wait, auto-create it on the
    default index set so learners still get real, selectable streams (fallback)."""
    index_sets = api("/api/system/indices/index_sets")["index_sets"]
    setprefix = {s["id"]: s["index_prefix"] for s in index_sets}
    def_set_id, def_prefix = default_index_set(index_sets)

    if ILLUMINATE_WAIT > 0:
        streams = wait_for_illuminate_streams(STREAM_TITLE_BY_PRODUCT.values(), ILLUMINATE_WAIT)
    else:
        streams = {s["title"]: s for s in api("/api/streams")["streams"]}

    routes = {}
    for product, title in STREAM_TITLE_BY_PRODUCT.items():
        s = streams.get(title)
        if s:
            prefix = setprefix.get(s["index_set_id"], def_prefix)
            routes[product] = (s["id"], prefix + "_deflector")
            log(f"route {product:16} -> stream {s['id']} / {prefix}_deflector (Illuminate)")
            continue
        # Still missing after the wait -> create it on the default index set (fallback).
        sid = create_stream(title, def_set_id)
        if sid:
            routes[product] = (sid, def_prefix + "_deflector")
            log(f"route {product:16} -> stream {sid} / {def_prefix}_deflector (auto-created '{title}')")
        else:
            log(f"WARNING: could not create stream '{title}' — '{product}' docs -> Default")
    return routes


def main():
    files = sorted(glob.glob(os.path.join(DATA, "*.ndjson")))
    if not files:
        sys.exit(f"no *.ndjson in {DATA}")
    log(f"files: {[os.path.basename(f) for f in files]}")

    # pass 1: window_end = max timestamp across all files
    window_end = None
    for fp in files:
        for line in open(fp):
            line = line.strip()
            if not line:
                continue
            ts = parse_ts(json.loads(line)["timestamp"])
            if window_end is None or ts > window_end:
                window_end = ts
    launch = dt.datetime.now(dt.timezone.utc) if LAUNCH == "now" else parse_ts(LAUNCH)
    delta = launch - window_end
    log(f"window_end={window_end.isoformat()} launch={launch.isoformat()} "
        f"delta={int(delta.total_seconds())}s")

    wait_for_graylog()
    routes = build_routes()
    received_by = received_by_fields()
    log(f"OpenSearch {OS_URL} (auth={'jwt' if USE_JWT else 'none'})")
    key = jwt_key() if USE_JWT else b""
    ctx = _ctx_for(OS_URL)

    # pass 2: restamp + strip + bulk index
    total, errors, batch_lines, n_in_batch = 0, 0, [], 0
    for fp in files:
        for line in open(fp):
            line = line.strip()
            if not line:
                continue
            alias, doc = prep(json.loads(line), delta, routes, received_by)
            batch_lines.append(json.dumps({"index": {"_index": alias}}))
            batch_lines.append(json.dumps(doc))
            n_in_batch += 1
            if n_in_batch >= BATCH:
                cnt, errs = bulk(("\n".join(batch_lines) + "\n").encode(), key, ctx)
                total += cnt; errors += errs
                batch_lines, n_in_batch = [], 0
    if batch_lines:
        cnt, errs = bulk(("\n".join(batch_lines) + "\n").encode(), key, ctx)
        total += cnt; errors += errs

    log(f"indexed {total} docs ({errors} errors)")
    # Only a total failure should fail the OliveTin "Launch Dataset" button; a handful of
    # per-doc index errors is non-fatal (the dataset still loaded).
    if total == 0:
        sys.exit("no documents indexed — check OpenSearch reachability / stream routing")
    if errors:
        log(f"note: {errors} docs failed to index (non-fatal)")


if __name__ == "__main__":
    main()
