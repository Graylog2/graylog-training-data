#!/bin/bash
# Class config script for CLASS="ethan-test" (Academy MVP — Module 2 data).
# Called by /common/base_setup.sh after the Instruqt track setup lifecycle
# script clones graylog-training-data and stages this class's files.
#
# Workflow order (env first, then replay):
#   1. Common host setup (OliveTin, GreyNoise, GeoIP)
#   2. Stage log_data
#   3. Certs / course settings / content packs / theme / HTTPS / Illuminate
#   4. REPLAY our captured dataset last (load_lab_data.py) — so the Illuminate
#      streams/index sets exist before data flows. (Path A, validated: cooked docs
#      JWT bulk-indexed into the typed Illuminate index sets; arrays + field types
#      preserved 1:1.)

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

# --- 2b. Log Playback harness ---
# Installs the gl-log-replay systemd service (enabled but stopped). The learner
# toggles it via OliveTin (Log Playback On/Off). Per-challenge setup (Instruqt UI)
# swaps in configs/olivetin/playback.yaml to expose the buttons.
chmod +x /$CLASS/apps/event_replay/installer/install.sh
/$CLASS/apps/event_replay/installer/install.sh

# --- 2c. Stage the dataset loader to a cleanup-proof path ---
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

# --- 3b. Mod5/6 Impossible Travel provisioning ---
# Runs AFTER Illuminate so the `Illuminate:Palo Alto Messages` stream exists. Installs
# the Impossible Pipeline content pack (normalize + GeoIP), creates+enables the
# impossible_travel detection (retargeted to that stream's runtime id), and imports the
# Global Authentication Activity + User Travel Investigation dashboards. Idempotent.
# (Generic cp_inst.sh can't do this: it runs pre-Illuminate, and the dashboards aren't
# content packs / the detection needs a runtime-resolved stream id.)
GL_API_URL="https://localhost" python3 /$CLASS/scripts/provision_mod5_impossible.py

# --- 4. Provision the "Global GELF" input at boot ---
# The Demo Log OliveTin button sends a sample message THROUGH this input (onboarding),
# and load_lab_data stamps its id onto the dataset so both read as "Received by: Global
# GELF". Idempotent. (After docker_graylog_https.sh the API is HTTPS on 443.)
GL_API_URL="https://localhost" TLS_VERIFY=0 python3 /$CLASS/scripts/provision_input.py

# --- 5. Apply the class OliveTin config (buttons: Demo Log / Launch Dataset / Playback) ---
# setup_olivetin.sh (step 1) installed the DEFAULT config; swap ours in + restart so the
# buttons appear track-wide. Live path = /OliveTin-linux-amd64/config.yaml (symlink
# /etc/OliveTin, capital). Service is `OliveTin`. (Per-challenge button variation, if ever
# needed, is an Instruqt-UI challenge-setup step — not needed for Mod2, same buttons.)
cp /$CLASS/configs/olivetin/playback.yaml /etc/OliveTin/config.yaml
systemctl restart OliveTin

# --- 6. Dataset load is LEARNER-TRIGGERED, not at boot ---
# The learner clicks the OliveTin "Launch Dataset" button in challenge 1 to bulk-load
# the module dataset ONCE (configs/olivetin/playback.yaml); the other challenges reuse
# it. load_lab_data.py re-stamps to launch, preserves arrays/field types, waits for the
# Illuminate streams (routing into the real ones when present, else auto-creating),
# coerces hex process ids, and stamps gl2_source_input for the "Received by" line.
# NOTE: not run here on purpose — see the Launch Dataset button.

echo "Complete!"
