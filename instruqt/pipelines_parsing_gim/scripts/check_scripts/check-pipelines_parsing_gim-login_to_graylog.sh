#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

users=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/users?include_permissions=false&include_sessions=true' -H 'Content-Type: application/json' | jq -r '.users[].last_activity | select (. != null)')
if [ -z "$users" ];then 
    fail-message "Oops, it looks like you still need to login to graylog";  
fi