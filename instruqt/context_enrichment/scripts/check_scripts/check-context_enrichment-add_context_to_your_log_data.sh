#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Get Pipeline ID
pipeid=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/pipeline" | jq -r '.[] | select(.title=="Desktop Firewalls") | .id')

#Check if rules created acording to instructions
ruleid=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/rule" | jq -r '.[] | select(.title=="Context - Desktop Firewalls - External Destination") | .id')
if [ -z "$ruleid" ];then 
    fail-message "Oops, it looks like you still need create the Context - \"Desktop Firewalls - External Destination\" rule!";  
    exit 0
fi

ruleid=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/rule" | jq -r '.[] | select(.title=="Context - Desktop Firewalls - External Source") | .id')
if [ -z "$ruleid" ];then 
    fail-message "Oops, it looks like you still need create the Context - \"Context - Desktop Firewalls - External Source\" rule!";  
    exit 0
fi

#Check if rules were ADDED to the pipeline
pljson=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/pipeline/$pipeid")
plrules=$(echo $pljson | jq -r '.stages | .[].rules')
if [[ $plrules != *"Context - Desktop Firewalls - Internal Destination"* ]]; then
    fail-message "Oops, it looks like you still need to add your \"Context - Desktop Firewalls - Internal Destination\" rule to the Desktop Firewalls pipeline"
    exit 0
fi
if [[ $plrules != *"Context - Desktop Firewalls - Internal Source"* ]]; then
    fail-message "Oops, it looks like you still need to add your \"Context - Desktop Firewalls - Internal Source\" rule to the Desktop Firewalls pipeline"
    exit 0
fi

if [[ $plrules != *"Context - Desktop Firewalls - External Source"* ]]; then
    fail-message "Oops, it looks like you still need to add your \"Context - Desktop Firewalls - External Source\" rule to the Desktop Firewalls pipeline"
    exit 0
fi
if [[ $plrules != *"Context - Desktop Firewalls - External Destination"* ]]; then
    fail-message "Oops, it looks like you still need to add your \"Context - Desktop Firewalls - External Destination\" rule to the Desktop Firewalls pipeline"
    exit 0
fi

#Check if logs have required fields
rule=$(curl -X GET "localhost:9200/_search?size=1" -H 'Content-Type: application/json' -d '{"query":{"exists":{"field":"destination_is_external"}}}' | jq '.hits.hits[]._index')
if [ -z "$rule" ]; then
    fail-message "Oops, it looks like no logs have the \"destination_is_external\" field added! Go check your pipeline / rules / resend logs"
    exit 0
fi

rule=$(curl -X GET "localhost:9200/_search?size=1" -H 'Content-Type: application/json' -d '{"query":{"exists":{"field":"source_is_internal"}}}' | jq '.hits.hits[]._index')
if [ -z "$rule" ]; then
    fail-message "Oops, it looks like no logs have \"the source_is_internal\" field added! Go check your pipeline / rules / resend logs"
    exit 0
fi

