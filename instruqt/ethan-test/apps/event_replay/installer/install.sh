#!/bin/bash
# Install the Log Playback harness: deps, service user, runner files, systemd unit.
# Installed ENABLED but STOPPED — the learner starts it via the OliveTin button.
# Idempotent: safe to re-run.
set -e
cd "$(dirname "$0")"

# python deps for the runner (PyYAML used by stub_replay.py)
PYBIN="$(command -v python3.12 || command -v python3.11 || command -v python3.10 || command -v python3.9 || command -v python3)"
"$PYBIN" -m pip install --ignore-installed PyYAML || true

# service user (idempotent: adduser is a no-op if it exists)
id gl_replay_service >/dev/null 2>&1 || \
  adduser --system --disabled-password --disabled-login --home /var/empty \
          --no-create-home --quiet --group gl_replay_service

# install dir + files
mkdir -p /opt/graylog/log-replay
cp -f ../stub_replay.py ../scenarios.yml /opt/graylog/log-replay/
cp -f service-wrapper.sh /opt/graylog/log-replay/
chmod +x /opt/graylog/log-replay/service-wrapper.sh

# env file for the service (Graylog is HTTPS on 443 after the https flip)
cat > /opt/graylog/log-replay/playback.env <<EOF
GL_API_URL=https://127.0.0.1
GL_API_USER=admin
GL_API_PASS=yabba dabba doo
GELF_HOST=127.0.0.1
GELF_PORT=12299
TLS_VERIFY=0
INTERVAL=10
EOF

touch /opt/graylog/log-replay/log.log
chown -R gl_replay_service:gl_replay_service /opt/graylog/log-replay

# install + enable (but DO NOT start) the unit
cp -f gl-log-replay.service /etc/systemd/system/gl-log-replay.service
systemctl daemon-reload
systemctl enable gl-log-replay.service

echo "Installed Log Playback harness to /opt/graylog/log-replay (service enabled, stopped)."
