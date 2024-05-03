#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#uninstall existing CP
id=$(cat setup-enrichment_context-enrich_challenge.json | jq -r '.id')
inst=$(curl -k https://localhost/api/system/content_packs/$id/installations -u 'admin:yabba dabba doo' | jq -r '.installations[]._id')
curl -u 'admin:yabba dabba doo' -k -XDELETE "https://localhost/api/system/content_packs/$id/installations/$inst" -H 'X-Requested-By: PS_Packer'

#Get Content Pack
wget https://github.com/Graylog2/graylog-training-data/raw/main/instruqt/context_enrichment/scripts/solve_scripts/solve-enrichment_context-enrich_challenge.json

id=$(cat solve-enrichment_context-enrich_challenge.json | jq -r '.id')
ver=$(cat solve-enrichment_context-enrich_challenge.json | jq -r '.rev')
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"solve-enrichment_context-enrich_challenge.json" 
curl -u'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}' 