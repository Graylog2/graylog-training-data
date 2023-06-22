#Set up log shipping stuffs
sudo apt install ncat -y

#Update Docker Config for new OT Ports
sed -i '/^      - "12201:12201\/udp" # GELF UDP.*/a\      - "5555:5555\/tcp"   # Raw TCP' /etc/graylog/docker-compose-glservices.yml
sed -i '/^      - "12201:12201\/udp" # GELF UDP.*/a\      - "1514:1514\/tcp"   # Syslog TCP' /etc/graylog/docker-compose-glservices.yml

#Update Graylog Container
docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d

#Load Abe's SwapShop!
docker run -p 7000:80 -d --restart always --log-driver gelf --log-opt gelf-address=tcp://localhost:12201 blueteamninja/swagshop

#Load Abe's Webhook Tester
docker run -p 8080:8080 -d --restart always tarampampam/webhook-tester

#Ricks Sysadmin stuffs!
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
echo "$graylog_ip graylog" >> /var/snap/lxd/common/lxd/containers/multivac/rootfs/etc/hosts
# start multivac!
#lxc start multivac
# execute multivac config script
#lxc exec multivac -- bash -c "$(cat multivac_config.sh)"

# Do Graylog launch and wait last...
#Wait for GL before api calls
while ! curl -s -k -u 'admin:yabba dabba doo' https://localhost/api/system/cluster/nodes; do
	printf "\n\nWaiting for GL to come online to add content\n"
    sleep 5
done

#Add GL inputs
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.raw.tcp.RawTCPInput","configuration":{"bind_address":"0.0.0.0","port":5555,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"RAW Data","global":true,"node":"93f01a3f-d051-436f-9bab-0c11f22cd55c"}'
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.syslog.tcp.SyslogTCPInput","configuration":{"bind_address":"0.0.0.0","port":1514,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"Syslog Data","global":true,"node":"93f01a3f-d051-436f-9bab-0c11f22cd55c"}'

#Move Log Data
mv "/Graylog - CTFd/log_data/" /etc/graylog/

#Update OT Config 
mv "/Graylog - CTFd/configs/olivetin/config.yaml" /etc/OliveTin/config.yaml
systemctl restart OliveTin.service

#Add course CPs
for entry in "/Graylog - CTFd/configs/content_packs/*"
do
  printf "\n\nInstalling Content Package: $entry\n"
  id=$(cat $entry | jq -r '.id')
  ver=$(cat $entry | jq -r '.rev')
  printf "\n\nID:$entry and Version: $ver\n"
  curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"$entry"
  printf "\n\nEnabling Content Package: $entry\n"
  curl -k -u'admin:yabba dabba doo' -XPOST "https://localhost/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}'
done

#Cleanup this folder so noones cheaters