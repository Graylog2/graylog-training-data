#!/bin/bash
#load Vars from Strigo
source /etc/profile

echo "Grabbing common scripts" >> /home/$LUSER/strigosuccess
apt install git-svn -y
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/common" >> /home/$LUSER/strigosuccess
chmod +x /common/*.sh

# Create /etc/graylog so certs.sh works right:
mkdir /etc/graylog

# Comment out all sections below that are not relevant to your specific course:

#DNS
./common/dns.sh >> /home/$LUSER/strigosuccess

#Cert Update
./common/certs.sh >> /home/$LUSER/strigosuccess

#Move Log Data
mv "/$STRIGO_CLASS_ID/log_data/" /etc/graylog/

#Course Settings
#./common/course_settings.sh >> /home/$LUSER/strigosuccess

#Update GL Docker Environment
## After this point everything will be HTTPS
#./common/docker_graylog_https.sh >> /home/$LUSER/strigosuccess

#Launch Docker to load changes in env file
#echo "Running Docker Compose to update GL environment with new information" >> /home/$LUSER/strigosuccess
#docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d

#Run this to speed up first run with OliveTin
wget https://github.com/OliveTin/OliveTin/releases/download/2023.03.25/OliveTin_linux_amd64.deb
sudo dpkg -i OliveTin_linux_amd64.deb 
sudo systemctl start OliveTin.service 
sudo systemctl enable OliveTin.service
mkdir -p /etc/OliveTin; ln -s /$STRIGO_CLASS_ID/.configs/config.yaml /etc/OliveTin

# Install NC

sudo apt-get install netcat -y

# Import course-specific setup script:
chmod +x ./$STRIGO_CLASS_ID/scripts/course_setup.sh
./$STRIGO_CLASS_ID/scripts/course_setup.sh >> /home/$LUSER/strigosuccess

#Add course Content Packs:
./common/cp_inst.sh >> /home/$LUSER/strigosuccess

#Illuminate Install
#./common/inst_illuminate.sh >> /home/$LUSER/strigosuccess

# Disable Input
echo "Stopping inputs" >> /home/$LUSER/strigosuccess
curl -u'admin:yabba dabba doo' -XDELETE  "http://localhost:9000/api/system/inputstates/650c1ae75d34aa3464372818" -H 'X-Requested-By: PS_TeamAwesome'
curl -u'admin:yabba dabba doo' -XDELETE  "http://localhost:9000/api/system/inputstates/650c1ae75d34aa346437286f" -H 'X-Requested-By: PS_TeamAwesome'

#OT Theme
./common/ot_gl_theme.sh >> /home/$LUSER/strigosuccess

#Cleanup
./common/cleanup.sh >> /home/$LUSER/strigosuccess

echo "All setup complete!" >> /home/$LUSER/strigosuccess