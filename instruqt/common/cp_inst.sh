#!/bin/bash
#load Vars from Strigo
source /etc/profile

# Install each content pack in class folder:
for entry in /$CLASS/configs/content_packs/*
do
  printf "\n\nInstalling Content Package: $entry\n" 
  id=$(cat "$entry" | jq -r '.id')
  ver=$(cat "$entry" | jq -r '.rev')
  printf "\n\nID:$entry and Version: $ver\n" 
  curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"$entry" 
  printf "\n\nEnabling Content Package: $entry\n" 
  curl -u'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}' 
done