#!/usr/bin/env python3
"""
provision_lab_streams.py — create the class's typed index sets + source streams at BOOT.

Why (see the QA thread 2026-07-17): the four Illuminate source streams
(Windows Security / Sysmon / PowerShell / Suricata) must EXIST, on their typed index
sets, before the learner opens the search page. Otherwise the runtime Launch Dataset
loader auto-creates them on the DEFAULT index set, which (a) causes the stream picker
availability race (the picker caches its list at page load), and (b) puts data on the
wrong index set.

The "natural" way to get these is to enable the Illuminate PROCESSING packs, but that
requires the LICENSED Illuminate bundle. The Framework's inst_illuminate.sh installs the
`+OPEN` (community) bundle, whose packs return HTTP 204 on enable but create nothing and
revert to disabled. So we create the structure DIRECTLY here instead — a faithful copy of
what Illuminate produces on a licensed box (verified against gl_sandbox's gl_* sets).

This is license-independent and deterministic. The Academy bulk-indexes cooked, already
enriched docs and bypasses Illuminate's processing pipelines entirely, so we gain nothing
from real pack activation — we only need the streams + typed index sets to EXIST, which is
exactly what this does. The Content Hub will show the packs disabled, which matches the
working sandbox's actual state (it also shows 0 packs enabled with the streams present).

Each index set uses the default `messages` template and its deflector is cycled to
materialize the physical write index (see ensure_write_index) — the loader bulk-indexes
into <prefix>_deflector, so that alias must exist before data flows.

Idempotent: skips any index set / stream that already exists (so if a future licensed
bundle DOES create them, this is a no-op). Env matches load_lab_data.py:
    GL_API_URL   default https://localhost
    GL_API_USER  default admin
    GL_API_PASS  default 'yabba dabba doo'
    TLS_VERIFY   default 0
"""
import os, sys, json, time, base64, ssl
import urllib.request, urllib.error
import datetime as dt

API    = os.environ.get("GL_API_URL", "https://localhost").rstrip("/")
USER   = os.environ.get("GL_API_USER", "admin")
PASS   = os.environ.get("GL_API_PASS", "yabba dabba doo")
VERIFY = os.environ.get("TLS_VERIFY", "0") not in ("0", "", "false", "False")

# The four streams and their typed index sets, cloned from gl_sandbox's Illuminate sets
# (index_template_type illuminate_content, TimeBasedSizeOptimizing rotation, Noop retention).
# (product key matches load_lab_data.py's STREAM_TITLE_BY_PRODUCT so routing lines up.)
LAB = [
    {"prefix": "gl_windows_security", "iset_title": "Windows Security Event Log Messages",
     "iset_desc": "Windows Security Event Log Messages",
     "stream_title": "Illuminate:Windows Security Event Log Messages",
     "stream_desc": "Windows Security Event Log Messages"},
    {"prefix": "gl_windows_sysmon", "iset_title": "Sysmon Event Messages",
     "iset_desc": "Microsoft Sysmon event log messages",
     "stream_title": "Illuminate:Sysmon;Messages",
     "stream_desc": "Windows Sysmon Event Log Messages"},
    {"prefix": "gl_powershell", "iset_title": "Powershell Logs",
     "iset_desc": "Powershell Messages",
     "stream_title": "Illuminate:Powershell Messages",
     "stream_desc": "Powershell Messages"},
    {"prefix": "gl_suricata", "iset_title": "Suricata IDS/IPS Logs",
     "iset_desc": "Suricata IDS/IPS EVE JSON Messages",
     "stream_title": "Illuminate:Suricata Messages",
     "stream_desc": "Suricata IDS/IPS EVE JSON messages"},
]


def log(m): print(f"[provision_lab_streams] {m}", flush=True)


def _ctx():
    if not API.startswith("https"):
        return None
    if VERIFY:
        return ssl.create_default_context()
    c = ssl.create_default_context(); c.check_hostname = False; c.verify_mode = ssl.CERT_NONE
    return c


def _hdr():
    return {"Authorization": "Basic " + base64.b64encode(f"{USER}:{PASS}".encode()).decode(),
            "Accept": "application/json", "Content-Type": "application/json",
            "X-Requested-By": "provision-lab-streams"}


def req(path, method="GET", body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(API + path, data=data, method=method, headers=_hdr())
    try:
        resp = urllib.request.urlopen(r, timeout=60, context=_ctx())
        raw = resp.read().decode()
        return resp.status, (json.loads(raw) if raw.strip() else {})
    except urllib.error.HTTPError as e:
        return e.code, {"error": e.read().decode()[:300]}


def wait_for_graylog():
    for _ in range(60):
        try:
            urllib.request.urlopen(API + "/api/system/lbstatus", timeout=5, context=_ctx())
            return
        except Exception:
            time.sleep(3)
    sys.exit("[provision_lab_streams] Graylog not reachable")


def index_set_body(prefix, title, desc):
    """The create payload. Uses the default `messages` template (dynamic mapping), NOT
    Illuminate's `illuminate_content` template: the latter references Illuminate OpenSearch
    component templates that only exist once the LICENSED packs are truly activated, so a
    deflector cycle on an illuminate_content index set fails 500 "Could not create new
    target index" on the +OPEN bundle (verified on both the datanode sandbox and a plain-
    OpenSearch iLab). The cooked docs carry their own field types and the loader coerces the
    hex process ids, so dynamic mapping indexes them fine — same behavior the loader's old
    default-index-set fallback relied on, just on separate typed index sets."""
    return {
        "title": title, "description": desc, "index_prefix": prefix,
        "shards": 1, "replicas": 0,
        "index_optimization_max_num_segments": 1, "index_optimization_disabled": False,
        "field_type_refresh_interval": 5000,
        "rotation_strategy_class": "org.graylog2.indexer.rotation.strategies.TimeBasedSizeOptimizingStrategy",
        "rotation_strategy": {
            "type": "org.graylog2.indexer.rotation.strategies.TimeBasedSizeOptimizingStrategyConfig",
            "index_lifetime_min": "P30D", "index_lifetime_max": "P365D"},
        "retention_strategy_class": "org.graylog2.indexer.retention.strategies.NoopRetentionStrategy",
        "retention_strategy": {
            "type": "org.graylog2.indexer.retention.strategies.NoopRetentionStrategyConfig",
            "max_number_of_indices": 20},
        "data_tiering": {"type": "hot_only", "index_lifetime_min": "P30D", "index_lifetime_max": "P40D"},
        "index_analyzer": "standard",
        "index_template_type": "messages",
        "creation_date": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
        "use_legacy_rotation": False,
        "writable": True,
    }


def ensure_index_set(existing, prefix, title, desc):
    """Return the index_set id for prefix, creating it if absent."""
    if prefix in existing:
        log(f"  index set {prefix} already exists")
        return existing[prefix]
    status, resp = req("/api/system/indices/index_sets", "POST",
                       index_set_body(prefix, title, desc))
    if status in (200, 201):
        log(f"  created index set {prefix}")
        return resp["id"]
    sys.exit(f"[provision_lab_streams] could not create index set {prefix} -> HTTP {status} {resp.get('error','')[:150]}")


def ensure_write_index(index_set_id, prefix):
    """A freshly-created index set has no physical write index until its deflector is
    cycled (Illuminate does this during pack activation; the API create does not). The
    loader bulk-indexes into <prefix>_deflector, so that alias MUST exist. Cycle the
    deflector if it is not already up, then confirm."""
    status, d = req(f"/api/system/deflector/{index_set_id}")
    if d.get("is_up") and d.get("current_target"):
        log(f"  write index for {prefix} already up ({d['current_target']})")
        return
    sc, sr = req(f"/api/system/deflector/{index_set_id}/cycle", "POST")
    if sc not in (200, 204):
        sys.exit(f"[provision_lab_streams] deflector cycle for {prefix} -> HTTP {sc} {sr.get('error','')[:150]}")
    for _ in range(12):
        _, d = req(f"/api/system/deflector/{index_set_id}")
        if d.get("is_up") and d.get("current_target"):
            log(f"  cycled write index for {prefix} ({d['current_target']})")
            return
        time.sleep(2)
    sys.exit(f"[provision_lab_streams] write index for {prefix} did not come up after cycle")


def ensure_stream(existing_titles, title, desc, index_set_id):
    if title in existing_titles:
        log(f"  stream '{title}' already exists")
        return
    # GL 7.x wraps the create body; a plain body 400s ("entity cannot be null").
    entity = {"title": title, "description": desc, "index_set_id": index_set_id,
              "remove_matches_from_default_stream": True}
    status, resp = req("/api/streams", "POST", {"entity": entity, "share_request": None})
    sid = resp.get("stream_id")
    if not sid:
        sys.exit(f"[provision_lab_streams] could not create stream '{title}' -> HTTP {status} {resp.get('error','')[:120]}")
    req(f"/api/streams/{sid}/resume", "POST")
    log(f"  created + resumed stream '{title}' on {index_set_id}")


def main():
    wait_for_graylog()
    isets = {s["index_prefix"]: s["id"] for s in req("/api/system/indices/index_sets")[1]["index_sets"]}
    stream_titles = {s["title"] for s in req("/api/streams")[1]["streams"]}
    for item in LAB:
        isid = ensure_index_set(isets, item["prefix"], item["iset_title"], item["iset_desc"])
        ensure_write_index(isid, item["prefix"])
        ensure_stream(stream_titles, item["stream_title"], item["stream_desc"], isid)
    # verify
    have = {s["title"] for s in req("/api/streams")[1]["streams"]}
    missing = [i["stream_title"] for i in LAB if i["stream_title"] not in have]
    if missing:
        sys.exit(f"[provision_lab_streams] FAILED: still missing streams {missing}")
    log("done: all 4 typed index sets + source streams present")


if __name__ == "__main__":
    main()
