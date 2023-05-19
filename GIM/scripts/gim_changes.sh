#NCAT handles UDP better
sudo apt install ncat -y

#Update OT Config
mv /home/ubuntu/GIT/GIM/configs/olivetin/config.yaml /OliveTin-linux-amd64/config.yaml
sudo systemctl restart OliveTin.service

#Update Docker Config for new OT Port
sed -i '/^      - "12201:12201\/udp" # GELF UDP.*/a\      - "5555:5555\/tcp"   # Raw TCP' /etc/graylog/docker-compose-glservices.yml

#Update Graylog Container
docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d

#Wait for GL before api calls
while ! curl -s -k -u 'admin:yabba dabba doo' https://localhost:9000/api/system/cluster/nodes; do
	printf "\n\nWaiting for GL to come online to add content\n"
    sleep 5
done

#Add TCP Raw input
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.raw.tcp.RawTCPInput","configuration":{"bind_address":"0.0.0.0","port":5555,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"PiHole Data","global":true,"node":"93f01a3f-d051-436f-9bab-0c11f22cd55c"}'

#Add course CPs
for entry in /home/ubuntu/GIT/GIM/configs/content_packs/*
do
  printf "\n\nInstalling Content Package: $entry\n"
  id=$(cat $entry | jq -r '.id')
  ver=$(cat $entry | jq -r '.rev')
  printf "\n\nID:$entry and Version: $ver\n"
  curl -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"$entry"
  printf "\n\nEnabling Content Package: $entry\n"
  curl -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}'
done