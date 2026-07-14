#!/usr/bin/env python3
"""provision_input.py — ensure the class's "Global GELF" input exists at boot.

Runs from config.sh at launch (before any challenge). Two consumers need it:
  * the **Demo Log** OliveTin button sends one sample message THROUGH this input so
    the learner sees data arrive with a real "Received by: Global GELF" line;
  * load_lab_data.py stamps its `gl2_source_input` onto the bulk-indexed docs so the
    dataset also reads as "Received by" that input (cosmetic — the data is still
    bulk-indexed; real input-flow is deferred to the module that needs it).

Idempotent: if the input already exists it is left as-is. Env (Framework defaults):
    GL_API_URL   default https://localhost   (HTTPS after the Framework flip)
    GL_API_USER  default admin
    GL_API_PASS  default 'yabba dabba doo'
    GELF_PORT    default 12201
    TLS_VERIFY   default 0
"""
import os, sys, json, base64, ssl, urllib.request, urllib.error

API   = os.environ.get("GL_API_URL", "https://localhost").rstrip("/")
USER  = os.environ.get("GL_API_USER", "admin")
PASS  = os.environ.get("GL_API_PASS", "yabba dabba doo")
PORT  = int(os.environ.get("GELF_PORT", "12201"))
VERIFY = os.environ.get("TLS_VERIFY", "0") not in ("0", "", "false", "False")
TITLE = "Global GELF"
GELF_TCP = "org.graylog2.inputs.gelf.tcp.GELFTCPInput"


def _ctx():
    if not API.startswith("https"):
        return None
    c = ssl.create_default_context()
    if not VERIFY:
        c.check_hostname = False
        c.verify_mode = ssl.CERT_NONE
    return c


def _req(path, method="GET", body=None):
    data = json.dumps(body).encode() if body is not None else None
    auth = base64.b64encode(f"{USER}:{PASS}".encode()).decode()
    r = urllib.request.Request(API + path, data=data, method=method, headers={
        "Authorization": f"Basic {auth}", "Accept": "application/json",
        "Content-Type": "application/json", "X-Requested-By": "lab-input"})
    raw = urllib.request.urlopen(r, timeout=30, context=_ctx()).read().decode()
    return json.loads(raw) if raw.strip() else {}


def main():
    existing = {i["title"]: i for i in _req("/api/system/inputs").get("inputs", [])}
    if TITLE in existing:
        print(f"[provision_input] '{TITLE}' already exists ({existing[TITLE]['id']})")
        return
    cfg = {"bind_address": "0.0.0.0", "port": PORT, "recv_buffer_size": 1048576,
           "number_worker_threads": 2, "tls_enable": False, "use_null_delimiter": True,
           "decompress_size_limit": 8388608, "max_message_size": 2097152,
           "tcp_keepalive": False}
    body = {"title": TITLE, "type": GELF_TCP, "global": True, "configuration": cfg}
    try:
        res = _req("/api/system/inputs", "POST", body)
    except urllib.error.HTTPError as e:
        sys.exit(f"[provision_input] create failed HTTP {e.code}: {e.read().decode()[:200]}")
    print(f"[provision_input] created '{TITLE}' GELF TCP :{PORT} -> {res.get('id')}")


if __name__ == "__main__":
    main()
