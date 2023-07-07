#!/bin/bash
#load Vars from Strigo
source /etc/profile

echo "Grabbing common scripts" >> /home/ubuntu/strigosuccess
apt install git-svn -y
#Certs
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/common" >> /home/ubuntu/strigosuccess
chmod +x /common/*.sh

#DNS
./common/dns.sh >> /home/ubuntu/strigosuccess

#Cert Update
./common/certs.sh >> /home/ubuntu/strigosuccess

#Illuminate Install
./common/inst_illuminate.sh >> /home/ubuntu/strigosuccess

#Course Settings
./common/course_settings.sh >> /home/ubuntu/strigosuccess

#Add course CPs
./common/cp_inst.sh >> /home/ubuntu/strigosuccess

#Update GL Docker Environment
## After this point everything will be HTTPS
./common/docker_chg.sh >> /home/ubuntu/strigosuccess

#Launch Docker to load changes in env file
echo "Running Docker Compose to update GL environment with new information" >> /home/ubuntu/strigosuccess
docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d

#Run this to speed up first run with OliveTin
pwsh -c 'write-host "loaded PS!"'

#Cleanup
./common/cleanup.sh >> /home/ubuntu/strigosuccess

echo "Complete!" >> /home/ubuntu/strigosuccess