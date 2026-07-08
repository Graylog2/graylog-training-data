#!/usr/bin/env python3
"""Log Playback stub feed: ensure a GELF HTTP input exists, then loop sending
heartbeat events into Graylog so live arrival is visible in search. Driven by
scenarios.yml; only the 'stub' feed is enabled for now. Real scenario generators
(palo_impossible, suricata_mimikatz) plug in here later.

Env (Framework defaults shown):
  GL_API_URL   default https://127.0.0.1     (Graylog REST, HTTPS after https flip)
  GL_API_USER  default admin
  GL_API_PASS  default 'yabba dabba doo'
  GELF_HOST    default 127.0.0.1
  GELF_PORT    default 12299
  TLS_VERIFY   default 0
  INTERVAL     default 10   (seconds between heartbeats)
  SCENARIOS    default <this dir>/scenarios.yml
"""
import os, sys, json, time, base64, ssl, urllib.request, urllib.error

try:
    import yaml
except ImportError:
    yaml = None

HERE = os.path.dirname(os.path.abspath(__file__))
API   = os.environ.get("GL_API_URL", "https://127.0.0.1").rstrip("/")
USER  = os.environ.get("GL_API_USER", "admin")
PASS  = os.environ.get("GL_API_PASS", "yabba dabba doo")
# IPv4 literal on purpose: "localhost" can resolve to ::1 first and hang urllib
# if Graylog binds v4-only (observed on the sandbox smoke test).
GELF_HOST = os.environ.get("GELF_HOST", "127.0.0.1")
GELF_PORT = int(os.environ.get("GELF_PORT", "12299"))
VERIFY = os.environ.get("TLS_VERIFY", "0") not in ("0", "", "false", "False")
INTERVAL = int(os.environ.get("INTERVAL", "10"))
SCENARIOS = os.environ.get("SCENARIOS", os.path.join(HERE, "scenarios.yml"))
INPUT_TITLE = "Lab Log Playback (GELF HTTP)"

def log(m): print(f"[stub_replay] {m}", flush=True)

# ---- pure logic (unit-tested) --------------------------------------------
def build_heartbeat(seq, now_ts):
    return {"version": "1.1", "host": "lab-playback",
            "short_message": f"log-playback heartbeat seq={seq}",
            "timestamp": now_ts,
            "_event_source_product": "lab_heartbeat", "_seq": seq}

def load_scenarios(path):
    if not os.path.exists(path):
        sys.exit(f"scenarios file not found: {path}")
    if yaml is None:
        sys.exit("PyYAML not installed (install.sh installs it)")
    with open(path) as f:
        return yaml.safe_load(f) or {}

def enabled_feed(scenarios):
    feeds = (scenarios or {}).get("feeds", {})
    on = [name for name, cfg in feeds.items() if (cfg or {}).get("enabled")]
    if len(on) != 1:
        sys.exit(f"exactly one feed must be enabled, found: {on}")
    return on[0]

# ---- Graylog plumbing -----------------------------------------------------
def _ctx():
    if not API.startswith("https"):
        return None
    c = ssl.create_default_context()
    if not VERIFY:
        c.check_hostname = False; c.verify_mode = ssl.CERT_NONE
    return c

def api(method, path, body=None):
    auth = base64.b64encode(f"{USER}:{PASS}".encode()).decode()
    h = {"Authorization": f"Basic {auth}", "X-Requested-By": "stub-replay",
         "Content-Type": "application/json", "Accept": "application/json"}
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(API + path, data=data, method=method, headers=h)
    try:
        resp = urllib.request.urlopen(r, timeout=30, context=_ctx())
        raw = resp.read().decode()
        return resp.status, (json.loads(raw) if raw.strip() else {})
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:300]

def ensure_gelf_input():
    st, data = api("GET", "/api/system/inputs")
    if st == 200:
        for inp in data.get("inputs", []):
            if inp.get("title") == INPUT_TITLE:
                log(f"GELF input exists: {inp['id']}"); return
    body = {"title": INPUT_TITLE, "global": True,
            "type": "org.graylog2.inputs.gelf.http.GELFHttpInput",
            "configuration": {"bind_address": "0.0.0.0", "port": GELF_PORT,
                              "recv_buffer_size": 1048576}}
    st, out = api("POST", "/api/system/inputs", body)
    log(f"create GELF input -> HTTP {st} {out if st not in (200,201) else out.get('id')}")

def send_gelf(doc):
    url = f"http://{GELF_HOST}:{GELF_PORT}/gelf"
    r = urllib.request.Request(url, data=json.dumps(doc).encode(),
                               headers={"Content-Type": "application/json"}, method="POST")
    try:
        resp = urllib.request.urlopen(r, timeout=10)
        return resp.status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception:
        return 0

def main():
    feed = enabled_feed(load_scenarios(SCENARIOS))
    log(f"enabled feed: {feed}")
    if feed != "stub":
        sys.exit(f"feed '{feed}' has no runner yet (only 'stub' implemented)")
    # ensure input (retry until Graylog is up)
    for _ in range(30):
        try:
            ensure_gelf_input(); break
        except Exception as e:
            log(f"waiting for Graylog: {e}"); time.sleep(5)
    seq = 0
    while True:
        seq += 1
        code = send_gelf(build_heartbeat(seq, time.time()))
        log(f"heartbeat seq={seq} -> {code}")
        time.sleep(INTERVAL)

if __name__ == "__main__":
    main()
