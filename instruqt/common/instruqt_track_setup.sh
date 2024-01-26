#!/bin/bash

# Instruqt Track Setup Lifecycle script.
# First script ran during course initialization.
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail

# To reduce issues with user prompts during package installation:
export DEBIAN_FRONTEND=noninteractive
echo "export DEBIAN_FRONTEND=noninteractive" >> /etc/profile

# Set License Details
cluster_id=${cluster_id}
license_enterprise=${license_enterprise}
license_security=${license_security}
gn_api_key=${gn_api_key}
authemail=${cloudflare_auth_email}
apitoken=${cloudflare_auth_token}
dns=${HOSTNAME}-${_SANDBOX_ID}

echo "export cluster_id=$cluster_id" >> /etc/profile
echo "export license_enterprise=$license_enterprise" >> /etc/profile
echo "export license_security=$license_security" >> /etc/profile
echo "export gn_api_key=$gn_api_key" >> /etc/profile
echo "export apitoken=$apitoken" >> /etc/profile
echo "export authemail=$authemail" >> /etc/profile
echo "export dns=$dns" >> /etc/profile

# Setup Class Information
# CLASS should be lowercase and match track's folder name in repo:
CLASS="analyst"
# TITLE should match "pretty" track name in Instruqt and 
# should use caps and spaces:
TITLE="Graylog Analyst"
echo "export CLASS=$CLASS" >> /etc/profile
echo "export TITLE=$TITLE" >> /etc/profile

# Uncomment below if this course needs a Graylog Docker environment:
# (Note: Setting this var to any value at all is interpreted as "yes")
echo "export NEEDS_DOCKER=yes" >> /etc/profile

# Cert Decode File
echo "${cert_pwd}" > /root/.pwd

# Base Apps
printf "\n\nGrabbing Base Apps"
sudo apt update
sudo apt install git -y

# Git Scripts Scripts
git clone --depth 1 https://github.com/Graylog2/graylog-training-data.git /graylog-training-data
mkdir -p /$CLASS
mv /graylog-training-data/instruqt/$CLASS/* /$CLASS/
sudo chmod +x /$CLASS/scripts/*.sh
mkdir -p /common/
mv /graylog-training-data/instruqt/common/* /common/
sudo chmod +x /common/*.sh
mkdir -p /certs
mv /graylog-training-data/certs/* /certs
rm -rf /graylog-training-data
# END FIX

# Run Base Install
printf "\n\nRunning Base Install"
/common/base_setup.sh