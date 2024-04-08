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

#Add Desktop Firewall Events Stream
##Get Index ID
indexID=$(curl -u 'admin:yabba dabba doo' -k -XGET "https://localhost/api/system/indices/index_sets?skip=0&limit=0&stats=false" | jq -r '.index_sets[] | select (.title=="General Desktop Events").id')
##Add Stream
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/streams"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d "{\"index_set_id\":\"$indexID\",\"description\":\"\",\"title\":\"Desktop Firewall Events\",\"remove_matches_from_default_stream\":false}"

##Start Stream
id=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/streams" | jq -r '.streams | .[] | select(.title=="Desktop Firewall Events") | .id')
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/streams/$id/resume" -H 'X-Requested-By: Skipper'

#Create Routing Rule
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/pipelines/rule"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d '{"description":"","source":"rule \"Route - Desktop Firewall - MS Logs\"\nwhen\n  from_input(\n    name : \"MS Logs\"\n  )\nthen\n  route_to_stream(\n    name : \"Desktop Firewall Events\",\n    remove_from_default : true\n  );\n  set_field(\n    field : \"route\",\n    value : \"Desktop Firewall - MS Logs\"\n  );\nend","simulator_message":"message: test\nsource: unknown\n"}'

#Create and update JSON to update pipeline with rules
echo '{"id":"66142fcc5d65c825334d325a","title":"Routing","description":"Route the logs!","source":"pipeline \"Routing\"\nstage 0 match either\nrule \"Route - My First Stream Logs\"\nrule \"Route - Desktop Firewall - MS Logs\"\nend"}' > pipeline.json
pipeID=$(curl -k -XGET -u 'admin:yabba dabba doo' https://localhost/api/system/pipelines/pipeline | jq -r '.[] | select (.title=="Routing").id')
sed -i "s/66142fcc5d65c825334d325a/$pipeID/g" pipeline.json
curl -u 'admin:yabba dabba doo' -k -XPUT "https://localhost/api/system/pipelines/pipeline/$pipeID" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"pipeline.json"
rm pipeline.json
