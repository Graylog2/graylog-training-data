# ethan-test — Academy MVP class (Module 2: Search Fundamentals)

Working class folder (`CLASS=ethan-test`, Rick's test-bed track) for the Academy →
Instruqt pilot. Loads our **canonical captured dataset** so a learner can practice the
Module 2 search workflow on real Graylog data.

Full design: `academy` repo → `docs/superpowers/specs/2026-06-18-mod2-instruqt-conversion-design.md`.

## Contents

```
scripts/
  config.sh          # class setup; runs common provisioning then replays our data LAST
  load_lab_data.py   # restamp + strip internal fields + GELF send (spike-confirmed)
log_data/
  mod2-3.sysmon.ndjson      # captured Sysmon (cooked Graylog docs)
  mod2-3.security.ndjson    # captured Windows Security
  mod2-3.powershell.ndjson  # captured PowerShell
  suricata_mimikatz.ndjson  # Unit-4 fixture: "Mimikatz" ONLY in raw `message` (no field)
configs/
  content_packs/     # (TBD) inputs / streams / saved searches
  olivetin/          # (TBD) Log Playback buttons
```

## How data gets in

**Static dataset (Mod2 searches work at launch):** `scripts/load_lab_data.py`
bulk-indexes the cooked `log_data/*.ndjson` straight into the typed Illuminate
index sets (restamped to launch, internal fields stripped, `streams` set per
`event_source_product`). Arrays + field types are preserved. NOT live; does not
use a GELF input. (The earlier GELF-through-an-input path was abandoned — Illuminate
won't reclassify cooked docs and strict mappings reject flattened arrays.)

**Live Log Playback (optional, per-challenge):** `apps/event_replay/` installs a
`gl-log-replay` systemd service (enabled, stopped). OliveTin buttons
(`configs/olivetin/playback.yaml`) toggle it: **On** = `systemctl start` →
`stub_replay.py` streams heartbeat events into a GELF HTTP input so live arrival is
visible in search; **Off** = `systemctl stop`. Real scenario generators
(palo_impossible, suricata_mimikatz) are seams in `apps/event_replay/scenarios.yml`,
disabled for now.

## MVP scope & status

- **MVP:** data loads and the Module 2 searches work (Default Stream, fully searchable).
  Mechanism validated against `gl_sandbox` (fields, roster, Unit-4 Mimikatz payoff).
- **Refinement (open):** routing into named streams. Stream rules on `event_source_product`
  route correctly (validated by probe), but routing the rich docs into the **Illuminate
  index set** needs a clean re-test (possible mapping conflict). **Do NOT** rely on enabling
  Illuminate *processing* for replayed data — it conflicts with already-cooked docs.

## Curriculum note

Unit 4 (message vs field): the "Mimikatz" indicator is intentionally present **only in the
raw `message`** of the Suricata events — no structured field carries it — so full-text
search finds it and field search does not.
