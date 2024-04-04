#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Create Rule Builder Rule
wget https://github.com/Graylog2/graylog-training-data/raw/main/instruqt/pipelines_parsing_gim/scripts/solve_content_packs/solve-pipelines_parsing_gim-kvp_rule.json
curl -XPOST -u 'admin:yabba dabba doo' -k "https://localhost/api/system/pipelines/rulebuilder" -H 'Content-Type: application/json' -H 'X-Requested-By: skipper' -d @"solve-pipelines_parsing_gim-kvp_rule.json"

#Update Training Pipeline with rule
pipeid=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/pipeline" | jq -r '.[] | select(.title=="Training") | .id')
wget https://github.com/Graylog2/graylog-training-data/raw/main/instruqt/pipelines_parsing_gim/scripts/solve_content_packs/solve-pipelines_parsing_gim-kvp_pipeline.json

#update pipelineID with sed
sed -i "s/660eec61faf32e49a3b50f45/$pipeid/g" solve-pipelines_parsing_gim-kvp_pipeline.json
curl -XPUT -u 'admin:yabba dabba doo' -k "https://localhost/api/system/pipelines/pipeline/$pipeid" -H 'Content-Type: application/json' -H 'X-Requested-By: skipper' -d @"solve-pipelines_parsing_gim-kvp_pipeline.json"

