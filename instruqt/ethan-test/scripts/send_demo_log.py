#!/usr/bin/env python3
"""send_demo_log.py — send ONE sample message through the Global GELF input.

Wired to the OliveTin "Demo Log" button. Its only job is the onboarding demo: the
learner clicks the button, a single message flows THROUGH the GELF input, and they
find it in Search shown as "Received by: Global GELF" — proving how log data gets
into the lab. It has nothing to do with the module dataset.

Sends GELF over TCP (null-delimited, no compression) to the local input.
Env: GELF_HOST default 127.0.0.1 (v4 literal — "localhost" can resolve ::1 and hang),
     GELF_PORT default 12201.
"""
import os, json, time, socket, sys

# IPv4 literal on purpose: localhost may resolve to ::1 first and hang if the input
# binds v4-only (observed on the sandbox smoke test).
HOST = os.environ.get("GELF_HOST", "127.0.0.1")
PORT = int(os.environ.get("GELF_PORT", "12201"))


def main():
    gelf = {
        "version": "1.1",
        "host": "graylog",
        "short_message": "Demo Message",
        "full_message": "This is my little message from me to you.  Enjoy your day!",
        "timestamp": time.time(),
        "level": 6,
    }
    payload = json.dumps(gelf).encode() + b"\x00"  # GELF TCP = null-terminated
    try:
        with socket.create_connection((HOST, PORT), timeout=10) as s:
            s.sendall(payload)
        print(f"[send_demo_log] sent demo message to {HOST}:{PORT}")
    except OSError as e:
        sys.exit(f"[send_demo_log] could not reach GELF input {HOST}:{PORT}: {e}")


if __name__ == "__main__":
    main()
