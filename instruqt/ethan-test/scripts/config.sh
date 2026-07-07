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

# --- 4. Replay our captured dataset LAST ---
# Re-stamps to launch, strips internal fields, and bulk-indexes each cooked doc
# straight into its Illuminate index set (routed by event_source_product), setting
# the doc's `streams` field so it appears under the right named stream. Arrays and
# field types (e.g. gim_event_type_code:integer) are preserved — required by later
# modules.
#
# The Framework deploys plain OpenSearch with the security plugin DISABLED
# (docker-compose-glservices.yml), so the bulk endpoint needs no auth — leave
# GL_PASSWORD_SECRET unset and the loader auto-selects no-auth mode. (If a future
# track moves to a datanode backend, set GL_PASSWORD_SECRET to the Graylog
# password_secret and the loader switches to JWT automatically.)
# The Graylog API is HTTPS on 443 after docker_graylog_https.sh; OpenSearch is the
# compose 'opensearch' service published on 9200.
export GL_API_URL="https://localhost"
export OS_URL="http://localhost:9200"
python3 /$CLASS/scripts/load_lab_data.py

echo "Complete!"
