#!/bin/bash

# Install Content Packs from course-specific repo directory.
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

# This is for Graylog 7.0 and newer
inst_cp_entity() {
  # Install each content pack in class folder:
  for entry in /$CLASS/configs/content_packs/*
  do
    printf "\n\nInstalling Content Package: $entry\n"
    id=$(cat "$entry" | jq -r '.id')
    ver=$(cat "$entry" | jq -r '.rev')
    printf "\n\nID:$entry and Version: $ver\n"
    curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"$entry"
    printf "\n\nEnabling Content Package: $entry\n"
    curl -u'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"entity":{"parameters":{},"comment":""}}'
  done
}

# This is for Graylog older than 7.0
inst_cp_legacy() {
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
}

# Check if this is a docker version
if [[ "$NEEDS_DOCKER" == "yes" ]]; then
  # Get the Graylog Docker Image version
  version=$(docker inspect --format='{{.Config.Image}}' root-graylog-1 | sed -rn 's|[^[:digit:]]+([[:digit:]]).+|\1|p')
else
  # Get the apt image version
  version=$(dpkg -s graylog-enterprise | grep '^Version:' | awk '{print $2}' | sed -rn 's|([[:digit:]]).+|\1|p')
fi

if [[ "$version" -ge "7" ]]; then
  inst_cp_entity
else
  inst_cp_legacy
fi