#!/bin/bash
#load Vars from Strigo
source /etc/profile
echo "Running GL OT Theming Script" >> /home/$LUSER/strigosuccess

#Tarball Install
DIR="/var/www/olivetin/themes"
if [ -d "$DIR" ]; then
    echo "Installing gl ot theme in ${DIR}..." >> /home/$LUSER/strigosuccess
    mv ./common/graylog-theme/ $DIR
fi

#Deb Install
DIR="/etc/OliveTin/webui/themes/"
if [ -d "$DIR" ]; then
    echo "Installing gl ot theme in ${DIR}..." >> /home/$LUSER/strigosuccess
    mv ./common/graylog-theme/ $DIR
fi

 