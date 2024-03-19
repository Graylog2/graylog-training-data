#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

wget https://raw.githubusercontent.com/Graylog2/graylog-training-data/main/instruqt/pipelines_parsing_gim/scripts/solve_content_packs/solve-pipelines_parsing_gim-create_pipeline_and_rule.json

#Change input ID here 65e9fca84e83fc6fa79c7669 is in content pack and will NEVER match :D 
#Get GELF Input
inputID=$(curl -k -XGET -u 'admin:yabba dabba doo' https://localhost/api/system/inputs | jq -r '.inputs[] | select(.name=="GELF TCP").id')

#update input with sed
sed -i "s/65e9fca84e83fc6fa79c7669/$inputID/g" solve-pipelines_parsing_gim-create_pipeline_and_rule.json

id=$(cat solve-pipelines_parsing_gim-create_pipeline_and_rule.json | jq -r '.id')
ver=$(cat solve-pipelines_parsing_gim-create_pipeline_and_rule.json | jq -r '.rev')
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"solve-pipelines_parsing_gim-create_pipeline_and_rule.json" 
curl -u'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}' 
