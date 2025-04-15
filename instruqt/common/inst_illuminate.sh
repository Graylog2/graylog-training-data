#!/bin/bash

# Install latest Illuminate version
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Wait for GL before changes
while ! curl -k -s -u 'admin:yabba dabba doo' https://localhost/api/system/cluster/nodes; do
	printf "\n\nWaiting for GL to come online to add content\n"
    sleep 5
done

#Setup Illuminate using API
printf "\n\nInstalling Illuminate" 
ilver=$(curl -u 'admin:yabba dabba doo' -XGET -k 'https://localhost/api/plugins/org.graylog.plugins.illuminate/bundles/hub/latest' | jq -r '.version')
printf "\n\nFound Illuminate Version:$ilver\n" 
ilinst=$(curl -u 'admin:yabba dabba doo' -XPOST -k "https://localhost/api/plugins/org.graylog.plugins.illuminate/bundles/hub/$ilver" -H 'X-Requested-By: PS_TeamAwesome')
printf "\n\nDownload Version $ilver - result: $ilinst\n" 
bunact=$(curl -u 'admin:yabba dabba doo' -XPOST -k "https://localhost/api/plugins/org.graylog.plugins.illuminate/bundles/$ilver" -H 'X-Requested-By: PS_TeamAwesome')
printf "\n\nInstallation Result: $bunact\n" 

# Add installed Illuminate bundle to /etc/profile for use in track & challenge lifecycle scripts:
printf "\nilluminate_ver=$ilver" >> /etc/profile