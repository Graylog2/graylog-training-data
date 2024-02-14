# Setup OliveTin:
/common/setup_olivetin.sh

# Setup Greynoise:
/common/setup_greynoise.sh

# Setup Maxmind GeoIP databases:
/common/setup_geoip.sh

#LogData
mkdir -p /etc/graylog/log_data
mv "/$CLASS/log_data/" /etc/graylog/

#Move Log Generating Scripts
mv "/$CLASS/scripts/nerdy_log_gen.sh" /etc/graylog/log_data
chmod +x /etc/graylog/log_data/nerdy_log_gen.sh

#Update OT Config 
echo "Updating OT"
mv "/$CLASS/configs/olivetin/config.yaml" /etc/OliveTin/config.yaml
systemctl restart OliveTin.service

#Creating Indices
printf "\n\n$(date)-Create General Desktop Events Index\n"
curl -u 'admin:yabba dabba doo' -XPOST 'http://localhost:9000/api/system/indices/index_sets' -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"title":"General Desktop Events","description":"General Desktop Events","index_prefix":"general-desktop","writable":true,"can_be_default":true,"shards":2,"replicas":0,"retention_strategy_class":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategy","retention_strategy":{"max_number_of_indices":3,"type":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategyConfig"},"index_analyzer":"standard","index_optimization_max_num_segments":1,"index_optimization_disabled":false,"field_type_refresh_interval":5000,"rotation_strategy_class":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategy","rotation_strategy":{"max_docs_per_index":20000,"type":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategyConfig"},"creation_date":"2022-08-17T21:06:47.393Z"}'
printf "\n\n$(date)-Create Training Index\n"
curl -u 'admin:yabba dabba doo' -XPOST 'http://localhost:9000/api/system/indices/index_sets' -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"title":"Training","description":"Training","index_prefix":"train","writable":true,"can_be_default":true,"shards":2,"replicas":0,"retention_strategy_class":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategy","retention_strategy":{"max_number_of_indices":3,"type":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategyConfig"},"index_analyzer":"standard","index_optimization_max_num_segments":1,"index_optimization_disabled":false,"field_type_refresh_interval":5000,"rotation_strategy_class":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategy","rotation_strategy":{"max_docs_per_index":20000,"type":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategyConfig"},"creation_date":"2022-08-17T21:06:47.393Z"}'

#Cert Injection
/common/certs.sh

#Course Settings
/common/course_settings.sh 

#Add course CPs
/common/cp_inst.sh 

#OT Theme
/common/ot_gl_theme.sh 

#Update Docker Compose with required inputs
sed -i '/^      - "12201:12201\/udp" # GELF UDP.*/a\      - "5555:5555\/tcp"   # Raw TCP 5555' /root/docker-compose-glservices.yml
sed -i '/^      - "12201:12201\/udp" # GELF UDP.*/a\      - "1514:1514\/tcp"   # Raw TCP 1514' /root/docker-compose-glservices.yml

#Update GL Docker Environment
## After this point everything will be HTTPS
/common/docker_graylog_https.sh

#Illuminate Install - moved to POST docker update. Illuminate doesn't seem to fetch first time graylog runs
/common/inst_illuminate.sh 

#Install ncat
sudo apt install ncat -y

#Load Abe's SwapShop!
echo "Setup docker containers"
docker run -p 7000:80 -d --restart always --log-driver gelf --log-opt gelf-address=tcp://localhost:12201 blueteamninja/swagshop

#Load Abe's Webhook Tester
docker run -p 8080:8080 -d --restart always tarampampam/webhook-tester

#Rick's Sysadmin stuffs!
echo "Setup The Graybeard" 
# Add a flag to the home directory passwords.txt
echo 'Who stored this flag in a password document?: Incredibly#Bad#Password#Security' > /home/ubuntu/passwords.txt
echo 'root@multivac - AlexanderAdell' >> /home/ubuntu/passwords.txt
chown ubuntu:ubuntu /home/ubuntu/passwords.txt
# get the docker bridge so we can add the lxc container to it, pretty sure this is illegal in 12 states
docker_bridge="br-"$(docker network list | grep 'root_default' | cut -f 1 -d ' ')
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
sed -i "s/ZZZZZGRAYLOGIPZZZZZ/$graylog_ip/" /$CLASS/scripts/multivac_config.sh
#echo "$graylog_ip graylog" >> /var/snap/lxd/common/lxd/containers/multivac/rootfs/etc/hosts
echo "172.18.10.10 multivac" >> /etc/hosts
# start multivac!
echo "Starting the Graybeard LXC" 
lxc start multivac 
# execute multivac config script
sidecar_user=$(curl -s -k -u 'admin:yabba dabba doo' "https://localhost/api/users?include_permissions=false&include_sessions=false" | jq -r '.users[] | select (.username=="graylog-sidecar") | .id')
sidecar_api=$(curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/users/$sidecar_user/tokens/ctf" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' | jq -r .token)
sed -i "s/ZZZZZTOKENTOKENZZZZZ/$sidecar_api/" /$CLASS/scripts/multivac_config.sh
lxc exec multivac -- bash -c "$(cat /$CLASS/scripts/multivac_config.sh)"

#Wait for GL before api calls
while ! curl -s -k -u 'admin:yabba dabba doo' https://localhost/api/system/cluster/nodes; do
	printf "\n\nWaiting for GL to come online to add content\n" 
    sleep 5
done

#Add GL inputs
echo "Adding inputs to Graylog via API" 
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.raw.tcp.RawTCPInput","configuration":{"bind_address":"0.0.0.0","port":5555,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"RAW Data","global":true,"node":"93f01a3f-d051-436f-9bab-0c11f22cd55c"}'
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.syslog.tcp.SyslogTCPInput","configuration":{"bind_address":"0.0.0.0","port":1514,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"Syslog Data","global":true,"node":"93f01a3f-d051-436f-9bab-0c11f22cd55c"}'