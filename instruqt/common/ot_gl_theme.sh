#!/bin/bash
#load Vars from Strigo
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