#!/bin/bash
# Class config script for CLASS="soc-mod3-search" (Academy Module 3: Working with
# Search Results). Sibling of the Module 2 class; same captured dataset, plus the
# Corp Inc SOC provisioning that Module 3's hand-off challenge needs.
# Called by /common/base_setup.sh after the Instruqt track setup lifecycle
# script clones graylog-training-data and stages this class's files.
#
# Workflow order (env first, then replay):
#   1. Common host setup (OliveTin, GreyNoise, GeoIP)
#   2. Stage log_data
#   3. Certs / course settings / content packs / theme / HTTPS / Illuminate,
#      then this class's streams (3a) and the Corp Inc SOC (3a-ii)
#   4. The dataset itself is loaded by the learner via OliveTin, NOT at boot
#      (see step 6), so the Illuminate streams/index sets exist before data flows.
#
# DIFFERENCES FROM THE MODULE 2 CLASS: no Log Playback harness (Module 3 never uses
# live replay) and no Mod5/6 Impossible Travel provisioning (different module, and
# it cost boot time here for nothing). The Suricata fixture is also absent: it exists
# for Module 2's full-text-vs-field unit, which Module 3 does not repeat.

# Import env vars (set in /etc/profile by the track "setup" lifecycle script:
# CLASS, TITLE, licenses, apitoken, dns, ...)
source /etc/profile

# --- 1. Common host setup ---
/common/setup_olivetin.sh
/common/setup_greynoise.sh
/common/setup_geoip.sh

# --- 2. Stage this class's log data ---
# Keep a copy in the PowerShell data dir (Framework convention) AND leave the
# originals in /$CLASS/log_data for the loader.
mkdir -p /root/powershell/Data
sudo cp /$CLASS/log_data/*.ndjson /root/powershell/Data/ 2>/dev/null || true
sudo chown -R root:root /root

# --- 2b. Stage the dataset loader to a cleanup-proof path ---
# /common/cleanup.sh runs LAST in setup and does `rm -r /$CLASS`, so the class
# folder is GONE by lab runtime. The "Launch Dataset" OliveTin button is clicked by
# the learner AFTER setup, so it cannot call /$CLASS/scripts/load_lab_data.py. Copy
# the loader + its dataset to /opt/lab (which cleanup does not touch) and point the
# button there. The loader resolves data as <script>/../log_data, so keep the same
# scripts/ + log_data/ sibling layout under /opt/lab.
mkdir -p /opt/lab
cp -r /$CLASS/scripts /$CLASS/log_data /opt/lab/

# --- 3. Course provisioning ---
/common/certs.sh
/common/course_settings.sh
/common/cp_inst.sh           # content packs (inputs / streams / saved searches)
/common/ot_gl_theme.sh
/common/docker_graylog_https.sh   # after this point everything is HTTPS
/common/inst_illuminate.sh

# --- 3a. Create the class's typed index sets + source streams at boot ---
# The four source streams (Windows Security / Sysmon / PowerShell / Suricata) must EXIST,
# on their typed index sets, before the learner opens the search page — otherwise the
# runtime Launch Dataset loader auto-creates them on the DEFAULT index set, which causes
# the QA stream-availability race (the picker caches its list at page load) and puts data
# on the wrong index set. The "natural" path (enable the Illuminate PROCESSING packs)
# needs the LICENSED Illuminate bundle; inst_illuminate.sh installs the +OPEN (community)
# bundle, whose packs enable with HTTP 204 but create nothing. So we create the structure
# directly here — a faithful copy of Illuminate's gl_* index sets + streams (verified
# against gl_sandbox). License-independent, deterministic; the loader then routes data
# into these real streams. Idempotent, so a future licensed bundle makes it a no-op.
# (Enabling the packs is deferred to fix A: licensed-bundle / input-based future content.)
GL_API_URL="https://localhost" TLS_VERIFY=0 \
  python3 /$CLASS/scripts/provision_lab_streams.py

# --- 3a-ii. Module 3 Corp Inc SOC (users / teams / collections) ---
# Runs AFTER 3a so the Windows Security stream exists for the team grant. Module 3's Save
# dialog exposes Add Collaborator and Add to collections inline; on a fresh lab both render
# empty, so the "hand your work to the team" workflow has nothing to point at. Creates four
# analyst personas (deliberately NOT the data roster, who are investigation subjects), three
# teams, two collections, and grants the SOC Analysts team `view` on the Windows Security
# stream so adding them as a collaborator does not raise the red dependency banner.
# Idempotent. Degrades gracefully if Teams (Enterprise) is unavailable.
GL_API_URL="https://localhost" TLS_VERIFY=0 \
  python3 /$CLASS/scripts/provision_soc_personas.py

# --- 4. Provision the "Global GELF" input at boot ---
# The Demo Log OliveTin button sends a sample message THROUGH this input (onboarding),
# and load_lab_data stamps its id onto the dataset so both read as "Received by: Global
# GELF". Idempotent. (After docker_graylog_https.sh the API is HTTPS on 443.)
GL_API_URL="https://localhost" TLS_VERIFY=0 python3 /$CLASS/scripts/provision_input.py

# --- 5. Apply the class OliveTin config (buttons: Demo Log / Launch Dataset) ---
# setup_olivetin.sh (step 1) installed the DEFAULT config; swap ours in + restart so the
# buttons appear track-wide. Live path = /OliveTin-linux-amd64/config.yaml (symlink
# /etc/OliveTin, capital). Service is `OliveTin`. All four Module 3 challenges use the
# same two buttons, so this is applied once here rather than per challenge.
cp /$CLASS/configs/olivetin/buttons.yaml /etc/OliveTin/config.yaml
systemctl restart OliveTin

# --- 6. Dataset load is LEARNER-TRIGGERED, not at boot ---
# The learner clicks the OliveTin "Launch Dataset" button in challenge 1 to bulk-load
# the module dataset ONCE (configs/olivetin/buttons.yaml); the other challenges reuse
# it. load_lab_data.py re-stamps to launch, preserves arrays/field types, waits for the
# Illuminate streams (routing into the real ones when present, else auto-creating),
# coerces hex process ids, and stamps gl2_source_input for the "Received by" line.
# NOTE: not run here on purpose — see the Launch Dataset button.

echo "Complete!"
