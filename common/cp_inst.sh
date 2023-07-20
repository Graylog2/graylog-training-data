#!/bin/bash
#load Vars from Strigo
source /etc/profile


for entry in /$STRIGO_CLASS_ID/configs/content_packs/*
do
  printf "\n\nInstalling Content Package: $entry\n" >> /home/$LUSER/strigosuccess
  id=$(cat "$entry" | jq -r '.id')
  ver=$(cat "$entry" | jq -r '.rev')
  printf "\n\nID:$entry and Version: $ver\n" >> /home/$LUSER/strigosuccess
  curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"$entry" >> /home/$LUSER/strigosuccess
  printf "\n\nEnabling Content Package: $entry\n" >> /home/$LUSER/strigosuccess
  curl -u'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}' >> /home/$LUSER/strigosuccess
done