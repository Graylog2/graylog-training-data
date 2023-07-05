#load Vars from Strigo
source /etc/profile

echo "Running DNS Registration Steps" >> /home/ubuntu/strigosuccess
dnscount=0
DNSMatch=false
#Check for Existing DNS Record
echo "Checking for existing record, result:" >> /home/ubuntu/strigosuccess
DNSCheck=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records?type=CNAME&name=$dns.logfather.org&match=all" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" | jq -r '.result[]')
echo $DNSCheck >> /home/ubuntu/strigosuccess
if [ ! -z "$DNSCheck" ]; then
    #Check it's CName to see if it matches existing DNS Record
    echo "Checking if CNAME is the same, result:" >> /home/ubuntu/strigosuccess
    CName=$(echo $DNSCheck | jq -r '.content')
    echo "$CName vs $LAB" >> /home/ubuntu/strigosuccess
    if [[ ! "$CName" == "$LAB" ]]; then
        #No Match - new DNS record but also need to check for more numbers
        #Loop through numbers and check for existing  DNS Records
        echo "Not a match, looping to find unused DNS record" >> /home/ubuntu/strigosuccess
        until [[ -z "$DNSCheck" ]];
        do
            #Add one to dnscount and check if that record exists. This will loop until null OR a matched CName is found in cases of paused labs THIS causes issues so lets fix it!
            ((dnscount++))
            DNSCheck=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records?type=CNAME&name=$dns$dnscount.logfather.org&match=all" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" | jq -r '.result[]')
            CName=$(echo $DNSCheck | jq -r '.content')
            echo "Comparing new DNS record's CNAME (if there is one), result" >> /home/ubuntu/strigosuccess
            echo $CName >> /home/ubuntu/strigosuccess
            if [[ "$CName" == "$LAB" ]]; then
                echo "$CName compared to $LAB is true..." 
                #If these match, ever, at all, exit the loop and set the DNS record below
                DNSMatch="true"
                break
            fi
        done
    fi
fi
#ONLY Update DNS Name IF there IS a count. Otherwise everyone is a zero. We don't like that.
if [ $dnscount -gt 0 ]; then
    dns="$dns$dnscount"
fi

#Only create a new DNS record if there isn't one already with a matching CName
if [[ ! "$DNSMatch" == "true" ]]; then
    #Create DNS Record
    echo "Creating DNS Record for: $dns" >> /home/ubuntu/strigosuccess
    cdata="{\"type\":\"CNAME\",\"name\":\"$dns\",\"content\":\"$LAB\",\"ttl\":3600,\"priority\":10,\"proxied\":false}"
    createcname=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" --data $cdata)
    result=$(echo $createcname | jq '.success')
    echo "Result: $result" >> /home/ubuntu/strigosuccess
fi
echo $dns >> /home/ubuntu/DNSSuccess
echo "Registered DNS record: $dns"
sed -i '/export dns=/d' /etc/profile
echo "export dns=$dns" >> /etc/profile

###Cert Update
echo "Grabbing Certs" >> /home/ubuntu/strigosuccess
apt install git-svn -y
#Certs
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs" >> /home/ubuntu/strigosuccess
echo "The present working directory is $(pwd)" >> /home/ubuntu/strigosuccess

## Copy Certs and Decode
echo "Decoding Certs" >> /home/ubuntu/strigosuccess
openssl enc -in /certs/privkey.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > /etc/graylog/privkey.pem
openssl enc -in /certs/cert.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > /etc/graylog/cert.pem
openssl enc -in /certs/fullchain.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > /etc/graylog/fullchain.pem
rm /.pwd
cp /certs/cacerts /etc/graylog/cacerts 

#Cert Permissions
chown root.root /etc/graylog/*.pem
chmod 600 /etc/graylog/*.pem

echo "Updating Keystore" >> /home/ubuntu/strigosuccess
keytool -import -trustcacerts -alias letsencryptcaroot  -file /etc/graylog/fullchain.pem -keystore /etc/graylog/cacerts -storepass changeit -noprompt >> /home/ubuntu/strigosuccess

cp /etc/graylog/fullchain.pem /usr/local/share/ca-certificates/fullchain.crt
update-ca-certificates

#Update GL Docker Environment
echo "Removing old variables" >> /home/ubuntu/strigosuccess
sed -i '/GLEURI=/d' /etc/graylog/strigo-graylog-training-changes.env
sed -i '/GLBINDADDR=/d' /etc/graylog/strigo-graylog-training-changes.env
sed -i '/GLTLS=/d' /etc/graylog/strigo-graylog-training-changes.env

echo "Adding updated variables" >> /home/ubuntu/strigosuccess
echo "GLBINDADDR=\"0.0.0.0:443\"" >> /etc/graylog/strigo-graylog-training-changes.env
echo "GLTLS=true" >> /etc/graylog/strigo-graylog-training-changes.env
echo "GLEURI=https://$dns.logfather.org/" >> /etc/graylog/strigo-graylog-training-changes.env

#Launch Docker to load changes in env file
echo "Running Docker Compose to update GL environment with new information" >> /home/ubuntu/strigosuccess
pwsh -c 'write-host "loaded PS!"'

#Set up log shipping stuffs
echo "Installing ncat" >> /home/ubuntu/strigosuccess
sudo apt install ncat -y >> /home/ubuntu/strigosuccess

#Update Docker Config for new OT Ports
echo "Adding required inputs to GL" >> /home/ubuntu/strigosuccess
sed -i '/^      - "12201:12201\/udp" # GELF UDP.*/a\      - "5555:5555\/tcp"   # Raw TCP' /etc/graylog/docker-compose-glservices.yml
sed -i '/^      - "12201:12201\/udp" # GELF UDP.*/a\      - "1514:1514\/tcp"   # Syslog TCP' /etc/graylog/docker-compose-glservices.yml

#Update Graylog Container
docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d

#Load Abe's SwapShop!
echo "Setup docker containers" >> /home/ubuntu/strigosuccess
docker run -p 7000:80 -d --restart always --log-driver gelf --log-opt gelf-address=tcp://localhost:12201 blueteamninja/swagshop >> /home/ubuntu/strigosuccess

#Load Abe's Webhook Tester
docker run -p 8080:8080 -d --restart always tarampampam/webhook-tester >> /home/ubuntu/strigosuccess

#Wait for GL before api calls
while ! curl -s -k -u 'admin:yabba dabba doo' https://localhost/api/system/cluster/nodes; do
	printf "\n\nWaiting for GL to come online to add content\n" >> /home/ubuntu/strigosuccess
    sleep 5
done

#Rick's Sysadmin stuffs!
echo "Setup The Graybeard" >> /home/ubuntu/strigosuccess
# Add a flag to the home directory passwords.txt
echo 'Who stored this flag in a password document?: Incredibly#Bad#Password#Security' > /home/ubuntu/passwords.txt
echo 'root@multivac - AlexanderAdell' >> /home/ubuntu/passwords.txt
chown ubuntu:ubuntu /home/ubuntu/passwords.txt
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
sed -i "s/ZZZZZGRAYLOGIPZZZZZ/$graylog_ip/" /$STRIGO_CLASS_IDscripts/multivac_config.sh
#echo "$graylog_ip graylog" >> /var/snap/lxd/common/lxd/containers/multivac/rootfs/etc/hosts
echo "172.18.10.10 multivac" >> /etc/hosts
# start multivac!
echo "Starting the Graybeard LXC" >> /home/ubuntu/strigosuccess
lxc start multivac >> /home/ubuntu/strigosuccess
# execute multivac config script
sidecar_api=$(curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/users/64820c50d55a8e608878168a/tokens/ctf" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' | jq -r .token)
sed -i "s/ZZZZZTOKENTOKENZZZZZ/$sidecar_api/" /$STRIGO_CLASS_IDscripts/multivac_config.sh
lxc exec multivac -- bash -c "$(cat /$STRIGO_CLASS_IDscripts/multivac_config.sh)"

#Add GL inputs
echo "Adding inputs to Graylog via API" >> /home/ubuntu/strigosuccess
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.raw.tcp.RawTCPInput","configuration":{"bind_address":"0.0.0.0","port":5555,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"RAW Data","global":true,"node":"93f01a3f-d051-436f-9bab-0c11f22cd55c"}'
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.syslog.tcp.SyslogTCPInput","configuration":{"bind_address":"0.0.0.0","port":1514,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8"},"title":"Syslog Data","global":true,"node":"93f01a3f-d051-436f-9bab-0c11f22cd55c"}'

#Move Log Data
mv "/$STRIGO_CLASS_ID/log_data/" /etc/graylog/

#Move Log Generating Scripts
mv "/$STRIGO_CLASS_ID/scripts/nerdy_log_gen.sh" /etc/graylog/log_data
chmod +x /etc/graylog/log_data/nerdy_log_gen.sh

#Update OT Config 
echo "Updating OT" >> /home/ubuntu/strigosuccess
mv "/$STRIGO_CLASS_ID/configs/olivetin/config.yaml" /etc/OliveTin/config.yaml
systemctl restart OliveTin.service

#Add course CPs
for entry in /$STRIGO_CLASS_ID/configs/content_packs/*
do
  printf "\n\nInstalling Content Package: $entry\n"
  id=$(cat "$entry" | jq -r '.id')
  ver=$(cat "$entry" | jq -r '.rev')
  printf "\n\nID:$entry and Version: $ver\n"
  curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"$entry"
  printf "\n\nEnabling Content Package: $entry\n"
  curl -k -u'admin:yabba dabba doo' -XPOST "https://localhost/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}'
done

#Cleanup this folder so noones cheaters
echo "Cleanup" >> /home/ubuntu/strigosuccess
sed -i '/export apitoken=/d' /etc/profile
sed -i '/export authemail=/d' /etc/profile
rm -r /certs
rm -r /$STRIGO_CLASS_ID

#Create file for lab to finally appear
touch /home/ubuntu/gogogo
echo "Complete!" >> /home/ubuntu/strigosuccess