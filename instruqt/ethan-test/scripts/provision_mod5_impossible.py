#!/usr/bin/env python3
"""Provision Mod5/6 Impossible Travel: install the Impossible Pipeline content pack,
create+enable the impossible_travel detection, and import the two dashboards
(Global Authentication Activity, User Travel Investigation).

Runs AFTER Illuminate is installed (so the `Illuminate:Palo Alto Messages` stream
exists) — the detection + dashboards are retargeted to that stream's runtime id.
Idempotent: skips anything already present, so re-runs (and a sandbox smoke-test)
are safe.

Env (Framework defaults shown):
  GL_API_URL   default https://localhost      (HTTPS after docker_graylog_https.sh)
  GL_API_USER  default admin
  GL_API_PASS  default 'yabba dabba doo'
  MOD5_DIR     default /$CLASS/configs/content_packs/mod5-impossible
  TLS_VERIFY   default 0
"""
import os, sys, json, base64, ssl, urllib.request, urllib.error

API   = os.environ.get("GL_API_URL", "https://localhost").rstrip("/")
USER  = os.environ.get("GL_API_USER", "admin")
PASS  = os.environ.get("GL_API_PASS", "yabba dabba doo")
CLASS = os.environ.get("CLASS", "ethan-test")
DIR   = os.environ.get("MOD5_DIR", f"/{CLASS}/configs/content_packs/mod5-impossible")
VERIFY = os.environ.get("TLS_VERIFY", "0") not in ("0", "", "false", "False")

PALO_TITLE  = "Illuminate:Palo Alto Messages"
PACK_ID     = "50b7e779-e61c-4399-a581-506449b999b5"
PACK_REV    = 1
# Palo Alto stream id embedded in the saved dashboard exports (from prox) — replaced
# at runtime with this environment's resolved stream id.
EXPORT_STREAM_ID = "6a2b46ddaf81e1f5811181eb"

def log(m): print(f"[provision_mod5] {m}", flush=True)

def _ctx():
    if not API.startswith("https"): return None
    c = ssl.create_default_context()
    if not VERIFY:
        c.check_hostname = False; c.verify_mode = ssl.CERT_NONE
    return c

def api(method, path, body=None, ok=(200, 201)):
    auth = base64.b64encode(f"{USER}:{PASS}".encode()).decode()
    h = {"Authorization": f"Basic {auth}", "X-Requested-By": "mod5-provision",
         "Content-Type": "application/json", "Accept": "application/json"}
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(API + path, data=data, method=method, headers=h)
    try:
        resp = urllib.request.urlopen(r, timeout=60, context=_ctx())
        raw = resp.read().decode()
        return resp.status, (json.loads(raw) if raw.strip() else {})
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:400]

def resolve_palo_stream():
    st, data = api("GET", "/api/streams")
    if st != 200:
        sys.exit(f"cannot list streams (HTTP {st})")
    for s in data.get("streams", []):
        if s["title"] == PALO_TITLE:
            return s["id"]
    sys.exit(f"stream '{PALO_TITLE}' not found — is Illuminate installed before this script?")

def install_pipeline_pack():
    # already installed?
    st, inst = api("GET", f"/api/system/content_packs/{PACK_ID}/installations")
    if st == 200 and isinstance(inst, dict) and inst.get("installations"):
        log("Impossible Pipeline pack already installed — skip"); return
    pack = json.load(open(f"{DIR}/impossible-pipeline.contentpack.json"))
    st, _ = api("POST", "/api/system/content_packs", pack)         # upload (201, or 4xx if exists)
    log(f"upload pack -> HTTP {st}")
    st, out = api("POST", f"/api/system/content_packs/{PACK_ID}/{PACK_REV}/installations",
                  {"entity": {"parameters": {}, "comment": "mod5 provision"}, "share_request": None})
    log(f"install pack -> HTTP {st}")
    if st not in (200, 201): log(f"  WARN pack install: {out}")

def ensure_detection(palo_stream):
    st, data = api("GET", "/api/events/definitions?per_page=500")
    if st == 200 and any(e.get("title") == "Impossible Travel Detection"
                         for e in data.get("event_definitions", [])):
        log("detection 'Impossible Travel Detection' already exists — skip"); return
    defn = {
        "title": "Impossible Travel Detection",
        "description": "Detects authentication activity from geographically distant locations occurring within an unrealistic time window.",
        "priority": 2, "alert": True,
        "config": {"type": "native-anomaly-v1", "filters": [], "streams": [palo_stream],
                   "stream_categories": [], "search_within_ms": 0, "execute_every_ms": 60000,
                   "use_cron_scheduling": False, "cron_expression": None, "cron_timezone": None,
                   "window_delay_ms": 60000,
                   "config": {"type": "impossible_travel", "user_field": "user_name",
                              "query": "event_type:vpn_login", "distance_threshold": 500,
                              "distance_unit": "km", "time_threshold_ms": 1800000, "lookback_ms": 7200000}},
        "key_spec": [], "notification_settings": {"grace_period_ms": 300000, "backlog_size": 0},
        "notifications": [], "storage": [{"type": "persist-to-streams-v1", "streams": ["000000000000000000000002"]}],
        "field_spec": {}}
    st, out = api("POST", "/api/events/definitions?schedule=true",
                  {"entity": defn, "share_request": None})
    if st not in (200, 201):
        log(f"  WARN detection create: HTTP {st} {out}"); return
    eid = out.get("id")
    st2, _ = api("PUT", f"/api/events/definitions/{eid}/schedule", ok=(200, 204))
    log(f"detection created {eid}, enable -> HTTP {st2}")

def import_dashboard(view_file, search_file, palo_stream):
    title = json.load(open(view_file)).get("title", view_file)
    st, existing = api("GET", "/api/views?page=1&per_page=500")
    if st == 200 and any(v.get("title") == title for v in existing.get("views", [])):
        log(f"dashboard '{title}' already exists — skip"); return
    remap = lambda o: json.loads(json.dumps(o).replace(EXPORT_STREAM_ID, palo_stream))
    search = remap(json.load(open(search_file)))
    for f in ("id", "created_at", "last_updated_at", "owner"): search.pop(f, None)
    st, sres = api("POST", "/api/views/search", search)
    if st not in (200, 201): log(f"  WARN '{title}' search: HTTP {st} {sres}"); return
    view = remap(json.load(open(view_file)))
    for f in ("id", "created_at", "last_updated_at", "owner"): view.pop(f, None)
    view["search_id"] = sres["id"]
    st, vres = api("POST", "/api/views", view)
    log(f"dashboard '{title}' -> HTTP {st}" + (f" id={vres.get('id')}" if st in (200,201) else f" {vres}"))

def main():
    palo = resolve_palo_stream()
    log(f"{PALO_TITLE} -> {palo}")
    install_pipeline_pack()
    ensure_detection(palo)
    import_dashboard(f"{DIR}/dashboard-global-auth-activity.view.json",
                     f"{DIR}/dashboard-global-auth-activity.search.json", palo)
    import_dashboard(f"{DIR}/dashboard-user-travel-investigation.view.json",
                     f"{DIR}/dashboard-user-travel-investigation.search.json", palo)
    log("done")

if __name__ == "__main__":
    main()
