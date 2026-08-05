# soc-mod3-search — Academy Module 3: Working with Search Results

Class folder for the Module 3 Instruqt track. `CLASS=soc-mod3-search`.

Module 3 continues the search journey Module 2 starts. The learner picks up a search
result and pivots from it instead of starting over, cuts recurring noise with filters,
saves the search so it survives a session, and turns it into a parameterized template
they hand off to their team.

Full design: `academy` repo →
`docs/superpowers/specs/2026-07-16-mod3-working-with-search-results-design.md`.

## Relationship to the Module 2 class

Separate track, separate folder, **same dataset**. The `log_data/mod2-3.*.ndjson` files
here are byte-identical to the Module 2 class's copies; git stores identical content once,
so the duplication costs a working-tree copy and nothing in the repo.

Do not try to share one folder between the two modules. One Instruqt track is one `CLASS`
is one folder, and the two modules provision different things.

What Module 3 adds:

- `scripts/provision_soc_personas.py` — the Corp Inc SOC, needed by the hand-off in
  Challenge 4.

What Module 3 drops (present in the Module 2 class, deliberately absent here):

- `apps/event_replay/` and the Log Playback OliveTin buttons. No Module 3 challenge uses
  live replay.
- `scripts/provision_mod5_impossible.py` and the `mod5-impossible` content packs. Different
  module; it only cost boot time here.
- `log_data/suricata_mimikatz.ndjson`. That fixture exists for Module 2's full-text-vs-field
  unit, which Module 3 does not repeat.

## Contents

```
scripts/
  config.sh                   # class setup, called by /common/base_setup.sh
  load_lab_data.py            # restamp + strip internal fields + bulk index
  provision_lab_streams.py    # step 3a: typed index sets + source streams, at boot
  provision_soc_personas.py   # step 3a-ii: SOC users, teams, collections, stream grant
  provision_input.py          # step 4: the Global GELF input behind "Received by"
log_data/
  mod2-3.sysmon.ndjson        # 3510 events
  mod2-3.security.ndjson      # 1105 events
  mod2-3.powershell.ndjson    # 8 events
configs/
  olivetin/buttons.yaml       # Demo Log + Launch Dataset, applied track-wide at boot
```

## How data gets in

`load_lab_data.py` bulk-indexes the cooked NDJSON straight into the typed Illuminate index
sets, restamped to launch time, internal fields stripped, `streams` set per
`event_source_product`. It is **learner-triggered**, not run at boot: the learner clicks
**Launch Dataset** in Challenge 1 and the other three challenges reuse the same data.

The class folder is deleted before lab runtime (`/common/cleanup.sh` does `rm -r /$CLASS`),
so config.sh step 2b copies the loader and its dataset to `/opt/lab` first. That is why the
button points at `/opt/lab/scripts/load_lab_data.py`.

## The Corp Inc SOC

`provision_soc_personas.py` runs at boot as config.sh **step 3a-ii**, after 3a so the stream
exists for the grant. It creates:

- Four personas: `dpatel`, `rmoreau`, `kbaptiste`, `jwarren`.
- Three teams: **SOC Analysts**, Threat Hunting, Incident Response.
- Two collections: **Corp Baseline Checks**, Investigation Views.
- `view` on `Illuminate:Windows Security Event Log Messages` for the SOC Analysts team.

Challenge 4 ends with the learner handing their saved search to the team, so these must
exist or the sharing dialog is an empty box. The stream grant is what stops a red "Team SOC
Analysts needs access to Stream" banner from firing mid-exercise.

The personas are deliberately **distinct from the data roster** (`vnovak`, `ocarter`,
`lrivera`): those accounts are the subjects of the investigations, and making them console
users would show a learner the same name as both suspect and teammate.

Idempotent, so a relaunch is a no-op. Teams and collections are Enterprise features; the
script degrades gracefully without them, but the Challenge 4 hand-off needs Enterprise.

## Instruqt UI setup

1. Track setup lifecycle script: set `CLASS="soc-mod3-search"`.
2. Four challenges; paste the text from the `academy` repo,
   `lab/instruqt/soc-mod3-search-challenges-PASTE.md`.
3. Tab layout, including a **dataset** tab for the OliveTin buttons (Challenge 1 tells the
   learner to click **Launch Dataset** there).

**No check or solve scripts.** In-lab is self-check with the answer revealed; the graded
gate is the LearnWorlds module quiz.
