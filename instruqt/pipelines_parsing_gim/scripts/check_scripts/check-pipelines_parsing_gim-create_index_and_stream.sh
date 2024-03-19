#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

index=$(curl -u 'admin:yabba dabba doo' -k -XGET "https://localhost/api/system/indexer/indices" | jq '.all.indices[] | select(.index_name=="mfi_0") | .index_name')
if [ -z "$id" ];then 
    fail-message "Oops, it looks like you still need create your first index"; 
    exit 0 
fi

id=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/streams" | jq -r '.streams | .[] | select(.title=="My First Stream") | .id')
if [ -z "$id" ];then 
    fail-message "Oops, it looks like you still need create your first stream";
    exit 0
fi