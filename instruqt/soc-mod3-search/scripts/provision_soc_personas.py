#!/usr/bin/env python3
"""
provision_soc_personas.py — create the Corp Inc SOC (users, teams, collections) at BOOT.

Why: Module 3 teaches saving and reusing a search, and the Save dialog contains
**Add Collaborator** and **Add to collections** inline. On a freshly built lab those
controls render empty (no other users, no teams, no collections), which makes the
"hand your work to the team" part of the module impossible to do and makes the shared
saved-search workflow look like a dead end.

These personas are deliberately DISTINCT from the data roster (vnovak, ocarter, lrivera,
...). Those accounts are the SUBJECTS of the investigations in the log data; making them
console users would put the same name in front of a learner as both suspect and teammate.

Idempotent: skips any user / team / collection that already exists, so re-running (or a
track relaunch) is a no-op. Env matches provision_lab_streams.py:
    GL_API_URL   default https://localhost
    GL_API_USER  default admin
    GL_API_PASS  default 'yabba dabba doo'
    SOC_PASSWORD default 'yabba dabba doo'   (shared lab password for the personas)
    TLS_VERIFY   default 0

MUST RUN AFTER inst_illuminate.sh / provision_lab_streams.py: the stream grant at the end
needs the Windows Security stream to exist.
"""
import os, sys, json, time, base64, ssl
import urllib.request, urllib.error

API    = os.environ.get("GL_API_URL", "https://localhost").rstrip("/")
USER   = os.environ.get("GL_API_USER", "admin")
PASS   = os.environ.get("GL_API_PASS", "yabba dabba doo")
SOCPW  = os.environ.get("SOC_PASSWORD", "yabba dabba doo")
VERIFY = os.environ.get("TLS_VERIFY", "0") not in ("0", "", "false", "False")

TEAMS_API       = "/api/plugins/org.graylog.plugins.security/teams"
COLLECTIONS_API = "/api/plugins/org.graylog.plugins.collections/collections"
SHARES_API      = "/api/authz/shares/entities/"

# (username, first, last, title, roles)
PERSONAS = [
    ("dpatel",    "Dev",    "Patel",    "SOC Analyst",        ["Reader", "Views Manager"]),
    ("rmoreau",   "Rowan",  "Moreau",   "Senior SOC Analyst", ["Reader", "Views Manager", "Dashboard Creator"]),
    ("kbaptiste", "Kim",    "Baptiste", "SOC Manager",        ["Reader", "Views Manager", "Report Creator"]),
    ("jwarren",   "Jordan", "Warren",   "Detection Engineer", ["Reader", "Views Manager"]),
]

# rmoreau overlaps all three on purpose, so the collaborator list reads like a real org
# rather than a seeding script.
TEAMS = [
    ("SOC Analysts",     "Tier 1 and Tier 2 analysts working the Corp Inc queue.",                  ["dpatel", "rmoreau"]),
    ("Threat Hunting",   "Proactive hunting across Windows, Sysmon, and PowerShell log data.",      ["rmoreau", "jwarren"]),
    ("Incident Response", "Escalation and containment for confirmed Corp Inc incidents.",           ["kbaptiste", "rmoreau"]),
]

COLLECTIONS = [
    ("Corp Baseline Checks", "Recurring baseline searches the SOC re-runs: logon activity, account scoping, per-system review."),
    ("Investigation Views",  "Dashboards and saved searches used while working an active Corp Inc investigation."),
]

# Stream access the teams need. Without this, naming a team as a collaborator on a saved
# search raises a red "Team X needs access to Stream: Y" dependency error in the Save
# dialog, mid-exercise.
# (stream title, {team name: capability})
STREAM_SHARES = [
    ("Illuminate:Windows Security Event Log Messages", {"SOC Analysts": "view"}),
]


def log(m): print(f"[provision_soc_personas] {m}", flush=True)


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
            "X-Requested-By": "provision-soc-personas"}


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
    sys.exit("[provision_soc_personas] Graylog not reachable")


def ensure_users():
    status, existing = req("/api/users")
    # Fail loudly on bad credentials. Without this check a 401 reads as "no users exist
    # yet", every create then 401s too, and the script still exits 0 with nothing done.
    if status >= 400:
        sys.exit(f"[provision_soc_personas] cannot list users ({status}) "
                 f"as {USER!r} at {API} - check GL_API_USER / GL_API_PASS")
    have = {u["username"] for u in existing.get("users", [])}
    for username, first, last, title, roles in PERSONAS:
        if username in have:
            log(f"user  {username:<11} exists, skipped")
            continue
        # NOTE: user create requires an explicit "permissions": [] or it 400s.
        status, body = req("/api/users", "POST", {
            "username": username,
            "first_name": first,
            "last_name": last,
            "email": f"{username}@corp-inc.example",
            "password": SOCPW,
            "roles": roles,
            "permissions": [],
            "timezone": "UTC",
            "session_timeout_ms": 28800000,
        })
        log(f"user  {username:<11} {status} ({title}) {body if status >= 400 else ''}")


def ensure_teams():
    _, users_now = req("/api/users")
    ids = {u["username"]: u["id"] for u in users_now.get("users", [])}

    status, team_list = req(TEAMS_API)
    if status >= 400:
        # Teams are an Enterprise feature. On a lower tier this endpoint is absent; the
        # rest of the module still works, only the collaborator hand-off is unavailable.
        # Anything other than "not licensed / not installed" is worth shouting about,
        # because it means the lab is broken rather than merely unlicensed.
        expected = status in (402, 404)
        log(f"teams API unavailable ({status}), skipping teams and stream shares"
            f"{'' if expected else '  <-- UNEXPECTED, check the Graylog server log'}")
        return False
    have = {t["name"] for t in team_list.get("teams", [])}

    for name, description, members in TEAMS:
        if name in have:
            log(f"team  {name:<20} exists, skipped")
            continue
        # Teams AND collections POST bodies must be wrapped as {"entity": {...}}
        # (CreateEntityRequest) or they 400 "entity cannot be null".
        status, body = req(TEAMS_API, "POST", {"entity": {
            "name": name,
            "description": description,
            "users": [ids[m] for m in members if m in ids],
        }})
        log(f"team  {name:<20} {status} {body if status >= 400 else ''}")
    return True


def ensure_collections():
    status, coll_list = req(COLLECTIONS_API)
    if status >= 400:
        log(f"collections API unavailable ({status}), skipping")
        return
    have = {c.get("title", c.get("name")) for c in coll_list.get("collections", [])}
    for title, description in COLLECTIONS:
        if title in have:
            log(f"coll  {title:<22} exists, skipped")
            continue
        status, body = req(COLLECTIONS_API, "POST",
                           {"entity": {"title": title, "description": description}})
        log(f"coll  {title:<22} {status} {body if status >= 400 else ''}")


def share_streams():
    """Grant teams read access on the streams they collaborate over.

    WARNING: POST to the shares endpoint REPLACES the grantee list for that entity, and a
    body WITHOUT selected_grantee_capabilities CLEARS it. There is no GET (405; and
    /api/authz/shares/{grn} is 404), so always send the full desired map. Re-running is
    safe and idempotent; grantees added by hand on these streams are not preserved.
    """
    _, streams = req("/api/streams")
    stream_ids = {s["title"]: s["id"] for s in streams.get("streams", [])}

    _, team_list = req(TEAMS_API)
    team_ids = {t["name"]: t["id"] for t in team_list.get("teams", [])}

    for stream_title, grants in STREAM_SHARES:
        stream_id = stream_ids.get(stream_title)
        if not stream_id:
            log(f"share {stream_title!r} stream not found, skipped")
            continue
        capabilities = {}
        for team_name, capability in grants.items():
            team_id = team_ids.get(team_name)
            if not team_id:
                log(f"share team {team_name!r} not found, skipped")
                continue
            capabilities[f"grn::::team:{team_id}"] = capability
        if not capabilities:
            continue
        status, body = req(SHARES_API + f"grn::::stream:{stream_id}", "POST",
                           {"selected_grantee_capabilities": capabilities})
        log(f"share {stream_title} {status} -> {', '.join(grants)} {body if status >= 400 else ''}")


def main():
    wait_for_graylog()
    ensure_users()
    if ensure_teams():
        share_streams()
    ensure_collections()
    log("done")


if __name__ == "__main__":
    main()
