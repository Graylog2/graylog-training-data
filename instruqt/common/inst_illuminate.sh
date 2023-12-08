#!/bin/bash
#load Vars from Strigo
source /etc/profile

#Setup Illuminate using API
printf "\n\nInstalling Illuminate" 
ilver=$(curl -u 'admin:yabba dabba doo' -XGET -k 'https://localhost/api/plugins/org.graylog.plugins.illuminate/bundles/hub/latest' | jq -r '.version')
printf "\n\nFound Illuminate Version:$ilver\n" 
ilinst=$(curl -u 'admin:yabba dabba doo' -XPOST -k "https://localhost/api/plugins/org.graylog.plugins.illuminate/bundles/hub/$ilver" -H 'X-Requested-By: PS_TeamAwesome')
printf "\n\nDownload Version $ilver - result: $ilinst\n" 
bunact=$(curl -u 'admin:yabba dabba doo' -XPOST -k "https://localhost/api/plugins/org.graylog.plugins.illuminate/bundles/$ilver" -H 'X-Requested-By: PS_TeamAwesome')
printf "\n\nInstallation Result: $bunact\n" 