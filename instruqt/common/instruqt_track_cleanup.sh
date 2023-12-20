#!/bin/bash

# Instruqt Track Cleanup Lifecycle script.
# Runs when shutting down environment.
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -euxo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Delete Existing Public DNS Record for this VM
printf "\n\nRunning Track Cleanup"

printf "\n\nDeleting public DNS Record"
authemail="${cloudflare_auth_email}"
apitoken="${cloudflare_auth_token}"
id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" | jq -r ".result[] | select(.name | contains (\"$dns\")) | .id")
DeleteRecord=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records/$id" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json")
printf "\n\n$DeleteRecord"

printf "Completed Cleanup"