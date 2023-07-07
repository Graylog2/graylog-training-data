#!/bin/bash
#load Vars from Strigo
source /etc/profile

echo "Grabbing common scripts" >> /home/ubuntu/strigosuccess
apt install git-svn -y
#Certs
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/common" >> /home/ubuntu/strigosuccess
chmod +x /common/*.sh

#DNS
./common/dns.sh

#Cert Update
./common/certs.sh

#Illuminate Install
./common/inst_illuminate.sh

#Course Settings
./common/course_settings.sh

#Add course CPs
for entry in /$STRIGO_CLASS_ID/configs/content_packs/*
do
  printf "\n\nInstalling Content Package: $entry\n" >> /home/ubuntu/strigosuccess
  id=$(cat "$entry" | jq -r '.id')
  ver=$(cat "$entry" | jq -r '.rev')
  printf "\n\nID:$entry and Version: $ver\n" >> /home/ubuntu/strigosuccess
  curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"$entry" >> /home/ubuntu/strigosuccess
  printf "\n\nEnabling Content Package: $entry\n" >> /home/ubuntu/strigosuccess
  curl -u'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}' >> /home/ubuntu/strigosuccess
done

#Update GL Docker Environment
## After this point everything will be HTTPS
./common/docker_chg.sh

#Launch Docker to load changes in env file
echo "Running Docker Compose to update GL environment with new information" >> /home/ubuntu/strigosuccess
docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d
pwsh -c 'write-host "loaded PS!"'

#Cleanup
./common/cleanup.sh

echo "Complete!" >> /home/ubuntu/strigosuccess