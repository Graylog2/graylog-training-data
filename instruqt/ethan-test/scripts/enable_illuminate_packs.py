#!/usr/bin/env python3
"""
enable_illuminate_packs.py — enable the Illuminate PROCESSING packs this class needs,
at BOOT, so their source streams and typed index sets exist before the learner opens
the search page.

Why this exists:
  inst_illuminate.sh installs the Illuminate *bundle* but does not enable any packs.
  Without the PROCESSING packs enabled, the four source streams
  (Windows Security / Sysmon / PowerShell / Suricata) do not exist, and the dataset
  loader falls back to auto-creating them on the DEFAULT index set at button time.
  That produces three problems seen in QA:
    1. Intermittent "stream not available": the Graylog stream picker caches its list
       at page load, so streams created at runtime are missing until the page reloads.
    2. Streams land on the default index set instead of the typed Illuminate sets
       (gl_windows_security, gl_sysmon, gl_powershell, gl_suricata).
    3. Incongruence: a learner who opens the Illuminate Content Hub sees the packs
       DISABLED while the streams somehow exist.

  Enabling the packs here at boot fixes all three: the packs legitimately create the
  streams on their typed index sets, the Content Hub shows them ENABLED, and the loader
  (build_routes) then simply routes data into the real Illuminate streams. No loader
  change is needed.

Idempotent: reads the currently enabled packs and POSTs the UNION with our targets, so
re-running never disables anything and never duplicates. Then it waits for the four
source streams to appear before returning, so boot does not complete until they exist.

Env (same convention as load_lab_data.py):
    GL_API_URL   default https://localhost   (Graylog REST API; HTTPS after the flip)
    GL_API_USER  default admin
    GL_API_PASS  default 'yabba dabba doo'
    TLS_VERIFY   default 0 (self-signed lab certs)
    STREAM_WAIT  default 180   seconds to wait for the four streams after enabling
Exit non-zero if the packs cannot be enabled or the streams never appear, so a boot
failure is visible rather than silently papered over with default-index-set fallbacks.
"""
import os, sys, json, time, base64, ssl
import urllib.request, urllib.error

API    = os.environ.get("GL_API_URL", "https://localhost").rstrip("/")
USER   = os.environ.get("GL_API_USER", "admin")
PASS   = os.environ.get("GL_API_PASS", "yabba dabba doo")
VERIFY = os.environ.get("TLS_VERIFY", "0") not in ("0", "", "false", "False")
STREAM_WAIT = int(os.environ.get("STREAM_WAIT", "180"))

ILLUMINATE = "/api/plugins/org.graylog.plugins.illuminate"

# The source streams this class needs (must match load_lab_data.py's mapping).
REQUIRED_STREAMS = [
    "Illuminate:Windows Security Event Log Messages",
    "Illuminate:Sysmon;Messages",
    "Illuminate:Powershell Messages",
    "Illuminate:Suricata Messages",
]

# The PROCESSING packs that create those streams + their typed index sets. Matched by
# title prefix so a version bump (the "(YYYY.M.D)" suffix) does not break the match.
# The base Core processing pack is included as a dependency of the four.
def is_target_pack(title):
    t = title.strip()
    prefixes = (
        "Microsoft Windows Security (",
        "Microsoft Sysmon (",
        "PowerShell (",
        "Suricata IDS/IPS (",
    )
    if t.startswith(prefixes):
        return True
    # Base Core PROCESSING pack (e.g. "Core %%VERSION%%" / "Core (…)"), not the
    # "Core:DNS…" add-ons or any Spotlight variant.
    if t.startswith("Core ") and ":" not in t and "Spotlight" not in t:
        return True
    return False


def log(m): print(f"[enable_illuminate] {m}", flush=True)


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
            "X-Requested-By": "enable-illuminate"}


def req(path, method="GET", body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(API + path, data=data, method=method, headers=_hdr())
    resp = urllib.request.urlopen(r, timeout=30, context=_ctx())
    raw = resp.read().decode()
    return resp.status, (json.loads(raw) if raw.strip() else {})


def wait_for_graylog():
    for _ in range(60):
        try:
            urllib.request.urlopen(API + "/api/system/lbstatus", timeout=5, context=_ctx())
            return
        except Exception:
            time.sleep(3)
    sys.exit("[enable_illuminate] Graylog not reachable")


def get_bundle():
    """Return the installed Illuminate bundle (dict with 'version' and 'packs')."""
    _, bundles = req(f"{ILLUMINATE}/bundles")
    if not bundles:
        sys.exit("[enable_illuminate] no Illuminate bundle installed (inst_illuminate.sh must run first)")
    return bundles[0]


def stream_titles():
    _, d = req("/api/streams")
    return {s["title"] for s in d.get("streams", [])}


def main():
    wait_for_graylog()
    bundle = get_bundle()
    version = bundle["version"]
    packs = bundle["packs"]
    log(f"bundle {version}: {len(packs)} packs")

    already = {p["pack_id"] for p in packs if p.get("enabled")}
    targets, missing_titles = set(), []
    for p in packs:
        if is_target_pack(p["title"]):
            targets.add(p["pack_id"])
            log(f"  target: {p['title']} ({'already on' if p['pack_id'] in already else 'enabling'})")
    if not targets:
        sys.exit("[enable_illuminate] found no target PROCESSING packs by title — check pack titles")

    # If our four source streams already exist AND every target is already enabled,
    # there is nothing to do (idempotent fast path).
    have = stream_titles()
    if targets <= already and all(t in have for t in REQUIRED_STREAMS):
        log("all target packs already enabled and all source streams present; nothing to do")
        return

    enabled = sorted(already | targets)
    log(f"POST enabled_packs: {len(already)} already + {len(targets - already)} new = {len(enabled)} total")
    status, _ = req(f"{ILLUMINATE}/bundles/{version}", method="POST", body={"enabled_packs": enabled})
    log(f"enable request -> HTTP {status}")

    # Enablement is async: the packs create their streams + index sets shortly after.
    # Wait until every required source stream exists (or time out). Boot must not
    # complete before the streams are present, or the picker race returns.
    deadline = time.time() + STREAM_WAIT
    while True:
        have = stream_titles()
        missing = [t for t in REQUIRED_STREAMS if t not in have]
        if not missing:
            log(f"all {len(REQUIRED_STREAMS)} source streams present")
            break
        if time.time() >= deadline:
            sys.exit(f"[enable_illuminate] timed out after {STREAM_WAIT}s; still missing: {missing}")
        log(f"waiting for source streams… missing {len(missing)}/{len(REQUIRED_STREAMS)}")
        time.sleep(5)

    # Re-read the bundle and report whether the targets stuck. Illuminate Content Packs
    # require an ENTERPRISE license; on a lower tier (e.g. +OPS / +OPEN test environments)
    # Graylog reconciles them back to disabled shortly after enabling. Crucially, the
    # source streams they create during the brief enabled window PERSIST on their typed
    # index sets. The streams are the functional requirement (they exist, on the right
    # index sets, before the learner opens the search page), so a rollback is a WARNING,
    # not a boot failure — it only affects the cosmetic Content Hub "ENABLED" state, and
    # only on non-Enterprise tiers. On the Enterprise-licensed production lab the packs
    # stay enabled and the Content Hub is fully congruent.
    persisted = {p["pack_id"] for p in get_bundle()["packs"] if p.get("enabled")}
    dropped = [pid for pid in targets if pid not in persisted]
    if dropped:
        log(f"WARNING: {len(dropped)} target pack(s) rolled back to disabled after enabling. "
            f"Source streams persist and boot continues, but the Content Hub will show these "
            f"packs disabled. Investigate Illuminate license tier / reconciliation.")
    else:
        log("target packs enabled and persisted")
    log("done: source streams present on their index sets")


if __name__ == "__main__":
    main()
