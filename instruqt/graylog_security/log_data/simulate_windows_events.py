import json
import time
import random
import socket
import argparse
from datetime import datetime

# Parse command line arguments
parser = argparse.ArgumentParser(description="Simulate GELF logs and send to Graylog")
parser.add_argument("--host", required=True, help="Graylog server IP or hostname")
parser.add_argument("--port", type=int, required=True, help="Graylog server UDP port")
args = parser.parse_args()

GRAYLOG_HOST = args.host
GRAYLOG_PORT = args.port

# Sample GELF log templates
LOG_TEMPLATES = [
    {
        "version": "1.1",
        "host": "Server-E",
        "short_message": "Event logging service has shut down",
        "full_message": "The event logging service has been shut down on the system.",
        "_EventID": 1100,
        "_collector_node_id": "WIN-SERVERC",
        "_Severity": "INFO",
        "_SourceModuleType": "im_msvistalog",
        "_SourceName": "Microsoft-Windows-Security-Auditing",
        "_Channel": "Security",
        "_ThreadID": 1000,
        "_RecordNumber": 50932,
        "_SeverityValue": 1,
        "_ServiceName": "EventLog",
        "_ShutdownReason": "User Requested"
    },
    {
        "version": "1.1",
        "host": "Server-A",
        "short_message": "Audit events dropped by the transport",
        "full_message": "Audit events have been dropped due to a buffer overflow.",
        "_EventID": 1101,
        "_collector_node_id": "WIN-SERVERB",
        "_Severity": "ERROR",
        "_SourceModuleType": "im_msvistalog",
        "_SourceName": "Microsoft-Windows-Security-Auditing",
        "_Channel": "Security",
        "_ThreadID": 145,
        "_RecordNumber": 40921,
        "_SeverityValue": 4,
        "_DroppedEvents": 150,
        "_BufferSize": "1024 KB"
    },
    {
        "version": "1.1",
        "host": "Server-C",
        "short_message": "User logon successful",
        "full_message": "A user has successfully logged on to the system.",
        "_EventID": 4624,
        "_collector_node_id": "WIN-SERVERD",
        "_Severity": "INFO",
        "_SourceModuleType": "im_msvistalog",
        "_SourceName": "Microsoft-Windows-Security-Auditing",
        "_Channel": "Security",
        "_ThreadID": 345,
        "_RecordNumber": 60012,
        "_SeverityValue": 1,
        "_User": "JohnDoe",
        "_LogonType": 2
    },
    {
        "version": "1.1",
        "host": "Server-D",
        "short_message": "Failed login attempt detected",
        "full_message": "A failed login attempt was detected on the system.",
        "_EventID": 4625,
        "_collector_node_id": "WIN-SERVERE",
        "_Severity": "WARNING",
        "_SourceModuleType": "im_msvistalog",
        "_SourceName": "Microsoft-Windows-Security-Auditing",
        "_Channel": "Security",
        "_ThreadID": 789,
        "_RecordNumber": 70021,
        "_SeverityValue": 3,
        "_User": "UnknownUser",
        "_LogonType": 3
    },
    {
        "version": "1.1",
        "host": "Server-F",
        "short_message": "System reboot initiated",
        "full_message": "The system is shutting down for a reboot.",
        "_EventID": 1074,
        "_collector_node_id": "WIN-SERVERF",
        "_Severity": "INFO",
        "_SourceModuleType": "im_msvistalog",
        "_SourceName": "User32",
        "_Channel": "System",
        "_ThreadID": 1123,
        "_RecordNumber": 80231,
        "_SeverityValue": 1,
        "_ShutdownReason": "Planned Maintenance"
    },
    {
        "version": "1.1",
        "host": "Server-G",
        "short_message": "Logon attempt using explicit credentials",
        "full_message": "A logon was attempted using explicit credentials.",
        "_EventID": 4648,
        "_collector_node_id": "WIN-SERVERG",
        "_Severity": "INFO",
        "_SourceModuleType": "im_msvistalog",
        "_SourceName": "Microsoft-Windows-Security-Auditing",
        "_Channel": "Security",
        "_ThreadID": 567,
        "_RecordNumber": 90543,
        "_SeverityValue": 1,
        "_User": "Administrator",
        "_LogonProcess": "Advapi",
        "_AuthenticationPackage": "Negotiate"
    }
]

def generate_log():
    """
    Creates a GELF log entry by selecting a random template and updating the timestamp.
    """
    log = random.choice(LOG_TEMPLATES).copy()  # Avoid modifying original template
    log["_EventReceivedTime"] = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    return log

def send_log_to_graylog(log):
    """
    Sends a GELF log message to the Graylog server via UDP.
    """
    try:
        # Convert log to JSON format
        log_json = json.dumps(log)

        # Create a UDP socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.sendto(log_json.encode('utf-8'), (GRAYLOG_HOST, GRAYLOG_PORT))
        sock.close()

        print(f"Sent log: EventID={log['_EventID']} at {log['_EventReceivedTime']}")
    except Exception as e:
        print(f"Error sending log: {e}")

if __name__ == "__main__":
    print("Starting GELF log simulation...")
    while True:
        log_entry = generate_log()
        send_log_to_graylog(log_entry)

        # Wait between 5 to 10 seconds to simulate real log flow
        sleep_time = random.randint(5, 10)
        print(f"Next log in {sleep_time} seconds...\n")
        time.sleep(sleep_time)

