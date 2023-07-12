#!/bin/bash
#load Vars from Strigo
source /etc/profile

echo "Grabbing common scripts" >> /home/$LUSER/strigosuccess
apt install git-svn -y
#Certs
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/common" >> /home/$LUSER/strigosuccess
chmod +x /common/*.sh

#DNS
./common/dns.sh >> /home/$LUSER/strigosuccess

#Cert Update
./common/certs.sh >> /home/$LUSER/strigosuccess

#Illuminate Install
./common/inst_illuminate.sh >> /home/$LUSER/strigosuccess

#Course Settings
./common/course_settings.sh >> /home/$LUSER/strigosuccess

#Add course CPs
./common/cp_inst.sh >> /home/$LUSER/strigosuccess

#Update GL Docker Environment
## After this point everything will be HTTPS
./common/docker_chg.sh >> /home/$LUSER/strigosuccess


#NCAT handles UDP better
sudo apt install ncat -y >> /home/$LUSER/strigosuccess

#Update OT Config
echo "Updating OT configuration" >> /home/$LUSER/strigosuccess
mv /$STRIGO_CLASS_ID/configs/olivetin/config.yaml /OliveTin-linux-amd64/config.yaml
sudo systemctl restart OliveTin.service >> /home/$LUSER/strigosuccess

#Update Docker Config for new OT Port
echo "Adding required inputs to GL DC" >> /home/$LUSER/strigosuccess
sed -i '/^      - "12201:12201\/udp" # GELF UDP.*/a\      - "5555:5555\/tcp"   # Raw TCP' /etc/graylog/docker-compose-glservices.yml

#Update Graylog Container
echo "Restarting GL Docker to reflect changes" >> /home/$LUSER/strigosuccess
docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d >> /home/$LUSER/strigosuccess

#Wait for GL before api calls
while ! curl -s -k -u 'admin:yabba dabba doo' https://localhost/api/system/cluster/nodes; do
	printf "\n\nWaiting for GL to come online to add content\n" >> /home/$LUSER/strigosuccess
    sleep 5
done

#Cleanup
./common/cleanup.sh >> /home/$LUSER/strigosuccess

echo "Complete!" >> /home/$LUSER/strigosuccess