#!/bin/bash
#load Vars from Strigo
source /etc/profile

echo "Importing common scripts" >> /home/$LUSER/strigosuccess
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/common" >> /home/$LUSER/strigosuccess
chmod +x /common/*.sh

#DNS
./common/dns.sh >> /home/$LUSER/strigosuccess

#Cert Update
./common/certs.sh >> /home/$LUSER/strigosuccess

# Install Graylog if NOT running a Docker env:
if [ ! $(which docker) ]; then
    ./common/inst_graylog.sh >> /home/$LUSER/strigosuccess
fi

#Illuminate Install
./common/inst_illuminate.sh >> /home/$LUSER/strigosuccess

#Course Settings
./common/course_settings.sh >> /home/$LUSER/strigosuccess

#Add course Content Packs:
./common/cp_inst.sh >> /home/$LUSER/strigosuccess

#Update GL Docker Environment
## After this point everything will be HTTPS
if [ $(which docker) ]; then
    ./common/docker_chg.sh >> /home/$LUSER/strigosuccess
    #Launch Docker to load changes in env file
    echo "Running Docker Compose to update GL environment with new information" >> /home/$LUSER/strigosuccess
    docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d
else
    echo "Skipping execution of docker_chg.sh..." >> /home/$LUSER/strigosuccess
fi

#Run this to speed up first run with OliveTin
pwsh -c 'write-host "loaded PS!"'

# Import course-specific setup script:
./$STRIGO_CLASS_ID/scripts/config_custom.sh >> /home/$LUSER/strigosuccess

#OT Theme
./common/ot_gl_theme.sh >> /home/$LUSER/strigosuccess

#Cleanup
./common/cleanup.sh >> /home/$LUSER/strigosuccess

echo "All setup complete!" >> /home/$LUSER/strigosuccess

# Create file for lab to finally appear
# (ref to Strigo init script)
touch /home/$LUSER/gogogo