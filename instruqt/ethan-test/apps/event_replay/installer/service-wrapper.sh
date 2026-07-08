#!/bin/bash
# Resolve the newest python3 and run the stub replay feed. Env comes from the
# systemd EnvironmentFile (playback.env); SCENARIOS defaults inside stub_replay.py.
set -e
PYBIN="$(command -v python3.12 || command -v python3.11 || command -v python3.10 || command -v python3.9 || command -v python3)"
echo "[service-wrapper] using $PYBIN"
exec "$PYBIN" /opt/graylog/log-replay/stub_replay.py
