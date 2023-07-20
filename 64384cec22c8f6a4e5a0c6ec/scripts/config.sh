#!/bin/bash
#load Vars from Strigo
source /etc/profile

echo "Grabbing common scripts" >> /home/$LUSER/strigosuccess
apt install git-svn -y
#Certs
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/common" >> /home/$LUSER/strigosuccess
chmod +x /common/*.sh

# Create /etc/graylog so certs.sh works right:
mkdir /etc/graylog

# Comment out all sections below that are not relevant to your specific course:

#DNS
./common/dns.sh >> /home/$LUSER/strigosuccess

#Cert Update
./common/certs.sh >> /home/$LUSER/strigosuccess

#Illuminate Install
#./common/inst_illuminate.sh >> /home/$LUSER/strigosuccess

#Course Settings
#./common/course_settings.sh >> /home/$LUSER/strigosuccess

#Add course CPs
#./common/cp_inst.sh >> /home/$LUSER/strigosuccess

#Update GL Docker Environment
## After this point everything will be HTTPS
#./common/docker_chg.sh >> /home/$LUSER/strigosuccess

#Launch Docker to load changes in env file
#echo "Running Docker Compose to update GL environment with new information" >> /home/$LUSER/strigosuccess
#docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d

#Run this to speed up first run with OliveTin
pwsh -c 'write-host "loaded PS!"'

# Import course-specific setup script:
chmod +x ./$STRIGO_CLASS_ID/scripts/course_setup.sh
./$STRIGO_CLASS_ID/scripts/course_setup.sh >> /home/$LUSER/strigosuccess

#Cleanup
./common/cleanup.sh >> /home/$LUSER/strigosuccess

echo "All setup complete!" >> /home/$LUSER/strigosuccess