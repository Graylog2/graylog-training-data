#!/bin/bash

# Miscellaneous Graylog configuration settings.
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Disable Whitelist
printf "\n\nDisable Whitelisting\n" 
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/urlwhitelist" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"entries":[],"disabled":true}' 

if [[ "$CLASS" == "threat_hunting" ]]; then
    #Threat Hunter
    #Pausing Endpoint Firewalls Stream
    printf "\n\nRetrieve Endpoint Firewalls Stream ID\n" 
    gnefstreamid=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/streams/paginated?page=1&per_page=50&query=Endpoint%20Firewalls&sort=title&order=asc' | jq -r '.elements[].id')
    printf "\n\nPausing Stream\n"
    curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/streams/$gnefstreamid/pause" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' 
fi