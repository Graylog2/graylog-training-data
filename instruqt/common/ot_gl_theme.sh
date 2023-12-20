#!/bin/bash

# Apply Graylog theme pack to OliveTin interface
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

echo "Running GL OT Theming Script" 

#Tarball Install
#DIR="/var/www/olivetin/themes"
#if [ -d "$DIR" ]; then
#    echo "Installing gl ot theme in ${DIR}..." 
#    mv ./common/graylog-theme/ $DIR
#fi

#Deb/Tar Install - SYMB Links made to make this the same
DIR="/etc/OliveTin/webui/themes/"
if [ -d "$DIR" ]; then
    echo "Installing gl ot theme in ${DIR}..." 
    mv /common/graylog-theme/ $DIR
fi

#Update OT Config 
echo "Updating OT" 
mv "/$CLASS/configs/olivetin/config.yaml" /etc/OliveTin/config.yaml
systemctl restart OliveTin.service