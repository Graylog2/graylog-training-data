# Mod5/6 — Impossible Travel (Illuminate-based) provisioning artifacts

Pulled from prox 2026-06-24; verified firing in gl_sandbox the same day.
These reconstitute the Impossible Travel detection + dashboards on top of the
**Illuminate** Palo Alto stream (`Illuminate:Palo Alto Messages`), which the
Palo Alto Illuminate pack creates. They do NOT create the Palo Alto input/stream.

## Files
- `impossible-pipeline.contentpack.json` — Graylog content pack: pipeline
  `Academy - Normalize GlobalProtect VPN Login` (sets `event_type=vpn_login`,
  `user_name`) + 5 static GeoIP rules (Phoenix/Austin/Dallas/Berlin) + the
  stream binding. Install via `/api/system/content_packs` then
  `/installations` (wrapped body `{"entity":{...},"share_request":null}`).
- `dashboard-global-auth-activity.{view,search}.json` — "Global Authentication
  Activity" dashboard (5 widgets).
- `dashboard-user-travel-investigation.{view,search}.json` — "User Travel
  Investigation" dashboard; search-level param `targetUser` ("Target User",
  default `eramirez`). Import: POST search → POST view (search_id=new id);
  string-replace the Palo Alto stream id to the target env's id first.

## NOT in this bundle (still needed for a full rebuild)
- **Detection event-def** (`Impossible Travel Detection`): native
  `impossible_travel` anomaly — `user_field:user_name`, `query:event_type:vpn_login`,
  500km / 30min / 2h lookback. Config lives in `../mod5-gi-bootstrap.json`;
  recreate retargeted to the Illuminate Palo Alto stream, then enable
  (`PUT /api/events/definitions/{id}/schedule`).
- **Palo Alto input (:5555) + stream**: from the Palo Alto Illuminate pack.

## Generate data to fire it
`SYSLOG_HOST=127.0.0.1 SYSLOG_PORT=5555 python3 lab/palo_globalproject_sim.py`
(eramirez Phoenix→Berlin lands in the detector's live window).
