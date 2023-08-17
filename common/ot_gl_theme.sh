#!/bin/bash
#load Vars from Strigo
source /etc/profile
echo "Running GL OT Theming Script" >> /home/$LUSER/strigosuccess

#Tarball Install
#DIR="/var/www/olivetin/themes"
#if [ -d "$DIR" ]; then
#    echo "Installing gl ot theme in ${DIR}..." >> /home/$LUSER/strigosuccess
#    mv ./common/graylog-theme/ $DIR
#fi

#Deb/Tar Install - SYMB Links made to make this the same
DIR="/etc/OliveTin/webui/themes/"
if [ -d "$DIR" ]; then
    echo "Installing gl ot theme in ${DIR}..." >> /home/$LUSER/strigosuccess
    mv ./common/graylog-theme/ $DIR
fi

#Update OT Config 
echo "Updating OT" >> /home/$LUSER/strigosuccess
mv "/$STRIGO_CLASS_ID/configs/olivetin/config.yaml" /etc/OliveTin/config.yaml
systemctl restart OliveTin.service