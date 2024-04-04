#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Create Syslog Input
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.syslog.tcp.SyslogTCPInput","configuration":{"bind_address":"0.0.0.0","port":1515,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"Syslog Data","global":true,"node":"93f01a3f-d051-436f-9bab-0c11f22cd55c"}'


#Get InputID and add to Illuminate table for them... Seriously this part sucks so...
inputID=$(curl -k -XGET -u 'admin:yabba dabba doo' https://localhost/api/system/inputs | jq -r '.inputs[] | select(.title=="Syslog Data").id')
curl -u 'admin:yabba dabba doo' -k -XPOST  "https://localhost/api/plugins/org.graylog.plugins.illuminate/overrides/4e6825b7-0276-4825-939d-44f28faac2a3" -H 'Content-Type: application/json' -H 'X-Requested-By: skipper' -d "{\"overrides\":{\"pfsense_firewall\":\"$inputID\"}}"