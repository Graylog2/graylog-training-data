#!/bin/bash
#load Vars from Strigo
source /etc/profile

#Setup Illuminate using API
printf "\n\nInstalling Illuminate" >> /home/ubuntu/strigosuccess
ilver=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/plugins/org.graylog.plugins.illuminate/bundles/hub/latest' | jq -r '.version')
printf "\n\nFound Illuminate Version:$ilver\n" >> /home/ubuntu/strigosuccess
ilinst=$(curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/plugins/org.graylog.plugins.illuminate/bundles/hub/$ilver" -H 'X-Requested-By: PS_TeamAwesome')
printf "\n\nDownload Version $ilver - result: $ilinst\n" >> /home/ubuntu/strigosuccess
bunact=$(curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/plugins/org.graylog.plugins.illuminate/bundles/$ilver" -H 'X-Requested-By: PS_TeamAwesome')
printf "\n\nInstallation Result: $bunact\n" >> /home/ubuntu/strigosuccess