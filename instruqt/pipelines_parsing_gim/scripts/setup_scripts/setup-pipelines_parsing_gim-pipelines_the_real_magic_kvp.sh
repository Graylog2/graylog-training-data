#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#add RAW TCP Input
curl -u 'admin:yabba dabba doo' -k -XPOST  "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: skipper' -d '{"type":"org.graylog2.inputs.raw.tcp.RawTCPIn
put","configuration":{"bind_address":"0.0.0.0","port":1514,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"di
sabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"RAW TCP","global":true,"node":"751f55bf-
11f2-4fb4-b962-2a9f7f2a04e4"}'