#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

ruleid=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/rule" | jq -r '.[] | select(.title=="Parse - Firewall - KVP") | .id')
if [ -z "$ruleid" ];then 
    fail-message "Oops, it looks like you still need create your KVP rule!";
    exit 0
fi

pipeid=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/pipeline" | jq -r '.[] | select(.title=="Training") | .id')
plrules=$(echo $pljson | jq -r '.stages | .[].rules')
if [[ $plrules != *"Parse - Firewall - KVP"* ]]; then
    fail-message "Oops, it looks like you still need to add your routing rule to the Training pipeline"
    exit 0
fi