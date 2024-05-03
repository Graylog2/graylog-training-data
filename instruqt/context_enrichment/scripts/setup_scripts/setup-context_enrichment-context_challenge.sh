#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Add Desktop Firewall Events Stream
##Get Index ID
indexID=$(curl -u 'admin:yabba dabba doo' -k -XGET "https://localhost/api/system/indices/index_sets?skip=0&limit=0&stats=false" | jq -r '.index_sets[] | select (.title=="General Desktop Events").id')
##Add Stream
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/streams"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d "{\"index_set_id\":\"$indexID\",\"description\":\"\",\"title\":\"Desktop Firewall Events\",\"remove_matches_from_default_stream\":false}"

##Start Stream
id=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/streams" | jq -r '.streams | .[] | select(.title=="Desktop Firewall Events") | .id')
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/streams/$id/resume" -H 'X-Requested-By: Skipper'

#Get Content Pack
wget https://github.com/Graylog2/graylog-training-data/raw/main/instruqt/context_enrichment/scripts/setup_scripts/setup-context_enrichment-context_challenge.json

id=$(cat setup-context_enrichment-context_challenge.json | jq -r '.id')
ver=$(cat setup-context_enrichment-context_challenge.json | jq -r '.rev')
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"setup-context_enrichment-context_challenge.json" 
curl -u'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}' 