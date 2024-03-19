#!/bin/bash
# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Remove CPs from previous lessons
cpid=$(curl -k -XGET -u 'admin:yabba dabba doo' https://localhost/api/system/content_packs | jq '.content_packs[] | select (.name=="solve-pipelines_parsing_gim-create_pipeline_and_rule").id' -r)
instid=$(curl -k -XGET -u 'admin:yabba dabba doo' https://localhost/api/system/content_packs/$cpid/installations | jq '.installations[]._id' -r)
curl -k -XDELETE -u 'admin:yabba dabba doo' https://localhost/api/system/content_packs/$cpid/installations/$instid -H "X-Requested-By:Graylog Service Delivery"

#Get Training Pipeline ID
pipeID=$(curl -k -XGET -u 'admin:yabba dabba doo' https://localhost/api/system/pipelines/pipeline | jq -r '.[] | select (.title=="Training").id')
#Delete the pipeline
curl -k -XDELETE -u 'admin:yabba dabba doo' https://localhost/api/system/pipelines/pipeline/$pipeID -H "X-Requested-By:Graylog Service Delivery"

pipeID=$(curl -k -XGET -u 'admin:yabba dabba doo' https://localhost/api/system/pipelines/pipeline | jq -r '.[] | select (.title=="Routing").id')
#Delete the pipeline
curl -k -XDELETE -u 'admin:yabba dabba doo' https://localhost/api/system/pipelines/pipeline/$pipeID -H "X-Requested-By:Graylog Service Delivery"

#Get Content Pack
wget https://github.com/Graylog2/graylog-training-data/raw/main/instruqt/pipelines_parsing_gim/scripts/solve_content_packs/solve-pipelines_parsing_gim-Okay_lets_actually_use_a_pipeline_to_add_data.json

#Change input ID here 65e9fca84e83fc6fa79c7669 is in content pack and will NEVER match :D 
#Get GELF Input
inputID=$(curl -k -XGET -u 'admin:yabba dabba doo' https://localhost/api/system/inputs | jq -r '.inputs[] | select(.name=="GELF TCP").id')

#update input with sed
sed -i "s/65f9f460d5e8272330e7c18a/$inputID/g" solve-pipelines_parsing_gim-Okay_lets_actually_use_a_pipeline_to_add_data.json

#Install Content Pack
id=$(cat solve-pipelines_parsing_gim-Okay_lets_actually_use_a_pipeline_to_add_data.json | jq -r '.id')
ver=$(cat solve-pipelines_parsing_gim-Okay_lets_actually_use_a_pipeline_to_add_data.json | jq -r '.rev')
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"solve-pipelines_parsing_gim-Okay_lets_actually_use_a_pipeline_to_add_data.json" 
curl -u'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}' 