#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

pipeid=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/pipeline" | jq -r '.[] | select(.title=="Desktop Firewalls") | .id')
if [ -z "$pipeid" ];then 
    fail-message "Oops, it looks like you still need create your pipeline!";
    exit 0
fi

ruleid=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/rule" | jq -r '.[] | select(.title=="Parse - Firewall - GROK") | .id')
if [ -z "$ruleid" ];then 
    fail-message "Oops, it looks like you still need create your GROK rule!";
    exit 0
fi

pljson=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/pipeline/$pipeid")
plrules=$(echo $pljson | jq -r '.stages | .[].rules')
if [[ $plrules != *"Parse - Firewall - GROK"* ]]; then
    fail-message "Oops, it looks like you still need to add your rule to your pipeline"
    exit 0
fi
