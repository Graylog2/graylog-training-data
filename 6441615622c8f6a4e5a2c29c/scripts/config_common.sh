#!/bin/bash
#load Vars from Strigo
source /etc/profile

echo "Grabbing common scripts" >> /home/$LUSER/strigosuccess
apt install git-svn -y >> /home/$LUSER/strigosuccess
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

#Set up log shipping stuffs
echo "Installing ncat" >> /home/$LUSER/strigosuccess
sudo apt install ncat -y >> /home/$LUSER/strigosuccess

#Update Docker Config for new OT Ports
echo "Adding required inputs to GL" >> /home/$LUSER/strigosuccess
sed -i '/^      - "12201:12201\/udp" # GELF UDP.*/a\      - "5555:5555\/tcp"   # Raw TCP' /etc/graylog/docker-compose-glservices.yml
sed -i '/^      - "12201:12201\/udp" # GELF UDP.*/a\      - "1514:1514\/tcp"   # Syslog TCP' /etc/graylog/docker-compose-glservices.yml

#Update GL Docker Environment
## After this point everything will be HTTPS
./common/docker_chg.sh >> /home/$LUSER/strigosuccess

#Load Abe's SwapShop!
echo "Setup docker containers" >> /home/$LUSER/strigosuccess
docker run -p 7000:80 -d --restart always --log-driver gelf --log-opt gelf-address=tcp://localhost:12201 blueteamninja/swagshop >> /home/$LUSER/strigosuccess

#Load Abe's Webhook Tester
docker run -p 8080:8080 -d --restart always tarampampam/webhook-tester >> /home/$LUSER/strigosuccess

#Rick's Sysadmin stuffs!
echo "Setup The Graybeard" >> /home/$LUSER/strigosuccess
# Add a flag to the home directory passwords.txt
echo 'Who stored this flag in a password document?: Incredibly#Bad#Password#Security' > /home/$LUSER/passwords.txt
echo 'root@multivac - AlexanderAdell' >> /home/$LUSER/passwords.txt
chown ubuntu:ubuntu /home/$LUSER/passwords.txt
# get the docker bridge so we can add the lxc container to it, pretty sure this is illegal in 12 states
docker_bridge="br-"$(docker network list | grep 'graylog_default' | cut -f 1 -d ' ')
# init LXD with a config
cat <<EOF | lxd init --preseed
config:
  images.auto_update_interval: "0"
networks: []
storage_pools:
- config: {}
  description: ""
  name: default
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: $docker_bridge
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
EOF
# init the LXC container with ubuntu focal
lxc init images:ubuntu/focal/amd64 multivac
# setup static IP for multivac container
cat <<EOF>/var/snap/lxd/common/lxd/containers/multivac/rootfs/etc/netplan/10-lxc.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      dhcp-identifier: mac
      addresses: [172.18.10.10/16]
      gateway4: 172.18.0.1
      nameservers:
        addresses: [1.1.1.1]
EOF
# setup hosts file resolution for graylog container in multivac
graylog_ip=$(docker container inspect -f '{{ .NetworkSettings.Networks.graylog_default.IPAddress }}' graylog-graylog-1)
sed -i "s/ZZZZZGRAYLOGIPZZZZZ/$graylog_ip/" /$STRIGO_CLASS_ID/scripts/multivac_config.sh
#echo "$graylog_ip graylog" >> /var/snap/lxd/common/lxd/containers/multivac/rootfs/etc/hosts
echo "172.18.10.10 multivac" >> /etc/hosts
# start multivac!
echo "Starting the Graybeard LXC" >> /home/$LUSER/strigosuccess
lxc start multivac >> /home/$LUSER/strigosuccess
# execute multivac config script
sidecar_user=$(curl -s -k -u 'admin:yabba dabba doo' "https://localhost/api/users?include_permissions=false&include_sessions=false" | jq -r '.users[] | select (.username=="graylog-sidecar") | .id')
sidecar_api=$(curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/users/$sidecar_user/tokens/ctf" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' | jq -r .token)
sed -i "s/ZZZZZTOKENTOKENZZZZZ/$sidecar_api/" /$STRIGO_CLASS_ID/scripts/multivac_config.sh
lxc exec multivac -- bash -c "$(cat /$STRIGO_CLASS_ID/scripts/multivac_config.sh)"

#Wait for GL before api calls
while ! curl -s -k -u 'admin:yabba dabba doo' https://localhost/api/system/cluster/nodes; do
	printf "\n\nWaiting for GL to come online to add content\n" >> /home/$LUSER/strigosuccess
    sleep 5
done

#Add GL inputs
echo "Adding inputs to Graylog via API" >> /home/$LUSER/strigosuccess
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.raw.tcp.RawTCPInput","configuration":{"bind_address":"0.0.0.0","port":5555,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"RAW Data","global":true,"node":"93f01a3f-d051-436f-9bab-0c11f22cd55c"}'
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.syslog.tcp.SyslogTCPInput","configuration":{"bind_address":"0.0.0.0","port":1514,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"Syslog Data","global":true,"node":"93f01a3f-d051-436f-9bab-0c11f22cd55c"}'
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.gelf.tcp.GELFTCPInput","configuration":{"bind_address":"0.0.0.0","port":12201,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":true,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8","decompress_size_limit":8388608},"title":"GELF TCP","global":true,"node":"3f46b40b-8399-46ad-80da-2deed2c29bd6"}'


#Move Log Data
mv "/$STRIGO_CLASS_ID/log_data/" /etc/graylog/

#Move Log Generating Scripts
mv "/$STRIGO_CLASS_ID/scripts/nerdy_log_gen.sh" /etc/graylog/log_data
chmod +x /etc/graylog/log_data/nerdy_log_gen.sh

#Update OT Config 
echo "Updating OT" >> /home/$LUSER/strigosuccess
mv "/$STRIGO_CLASS_ID/configs/olivetin/config.yaml" /etc/OliveTin/config.yaml
systemctl restart OliveTin.service

#OT Theme
./common/ot_gl_theme.sh >> /home/$LUSER/strigosuccess

#Cleanup
./common/cleanup.sh >> /home/$LUSER/strigosuccess

touch /home/$LUSER/gogogo
echo "Complete!" >> /home/$LUSER/strigosuccess