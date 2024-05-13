#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Get Pipeline ID
pipeid=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/pipeline" | jq -r '.[] | select(.title=="Desktop Firewalls") | .id')

#Check if rules were ADDED to the pipeline
pljson=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/pipeline/$pipeid")
plrules=$(echo $pljson | jq -r '.stages | .[].rules')

if [[ $plrules != *"Enrich - Destination - Threat Intelligence"* ]]; then
    fail-message "Oops, it looks like you still need to add your \"Enrich - Destination - Threat Intelligence\" rule to the Desktop Firewalls pipeline"
    exit 0
fi

if [[ $plrules != *"Enrich - Source - Threat Intelligence"* ]]; then
    fail-message "Oops, it looks like you still need to add your \"Enrich - Source - Threat Intelligence\" rule to the Desktop Firewalls pipeline"
    exit 0
fi

if [[ $plrules != *"Context - Threat Info - Destination"* ]]; then
    fail-message "Oops, it looks like you still need to add your \"Context - Threat Info - Destination\" rule to the Desktop Firewalls pipeline"
    exit 0
fi

if [[ $plrules != *"Context - Threat Info - Source"* ]]; then
    fail-message "Oops, it looks like you still need to add your \"Context - Threat Info - Source\" rule to the Desktop Firewalls pipeline"
    exit 0
fi

if [[ $plrules != *"Enrich - Source - Asset Management"* ]]; then
    fail-message "Oops, it looks like you still need to add your \"Enrich - Source - Asset Management\" rule to the Desktop Firewalls pipeline"
    exit 0
fi

#Check if logs have required fields
rule=$(curl -X GET "localhost:9200/_search?size=1" -H 'Content-Type: application/json' -d '{"query":{"exists":{"field":"destination_geo_coordinates"}}}' | jq '.hits.hits[]._index')
if [ -z "$rule" ]; then
    fail-message "Oops, it looks like no logs have the \"destination_geo_coordinates\" field added! Go check your pipeline / rules / resend logs"
    exit 0
fi

rule=$(curl -X GET "localhost:9200/_search?size=1" -H 'Content-Type: application/json' -d '{"query":{"exists":{"field":"threat_classification"}}}' | jq '.hits.hits[]._index')
if [ -z "$rule" ]; then
    fail-message "Oops, it looks like no logs have the \"threat_classification\" field added! Go check your pipeline / rules / resend logs"
    exit 0
fi

rule=$(curl -X GET "localhost:9200/_search?size=1" -H 'Content-Type: application/json' -d '{"query":{"exists":{"field":"threat_info_url"}}}' | jq '.hits.hits[]._index')
if [ -z "$rule" ]; then
    fail-message "Oops, it looks like no logs have the \"threat_info_url\" field added! Go check your pipeline / rules / resend logs"
    exit 0
fi


