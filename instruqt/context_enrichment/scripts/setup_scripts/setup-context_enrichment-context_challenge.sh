#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Get Content Pack
wget https://github.com/Graylog2/graylog-training-data/raw/main/instruqt/context_enrichment/scripts/setup_scripts/setup-context_enrichment-context_challenge.json

id=$(cat solve-pipelines_parsing_gim-pipelines-grok.json | jq -r '.id')
ver=$(cat solve-pipelines_parsing_gim-pipelines-grok.json | jq -r '.rev')
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"solve-pipelines_parsing_gim-pipelines-grok.json" 
curl -u'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}' 