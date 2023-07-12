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

#Add TCP Raw input
echo "Adding required inputs to GL" >> /home/$LUSER/strigosuccess
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.raw.tcp.RawTCPInput","configuration":{"bind_address":"0.0.0.0","port":5555,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"PiHole Data","global":true,"node":"93f01a3f-d051-436f-9bab-0c11f22cd55c"}'

#Move Log Data
echo "Moving Log Data" >> /home/$LUSER/strigosuccess
mv "/$STRIGO_CLASS_ID/log_data/" /etc/graylog/

#Cleanup
./common/cleanup.sh >> /home/$LUSER/strigosuccess

echo "Complete!" >> /home/$LUSER/strigosuccess