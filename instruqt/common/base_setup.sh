# Avoids warnings during package installations
export DEBIAN_FRONTEND=noninteractive
source /etc/profile

#Add Docker Repo
printf "\n\n$(date)-Adding Docker Repo\n"
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq
printf "\n\n$(date)-Adding keyring dir\n"
sudo mkdir -p /etc/apt/keyrings
printf "\n\n$(date)-$(date)adding gpg key\n"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
printf "\n\n$(date)-adding repo to apt\n"
printf "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
cat /etc/apt/sources.list.d/docker.list

#Install Software
printf "\n\n$(date)-Installing Software\n"
sudo mkdir /etc/graylog
sudo apt update
sudo apt upgrade -y

#Powershell
printf "\n\n$(date)-Setting up local log tooling\n"
sudo wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update -y
sudo apt-get install powershell -y

#Move "sendlogs" to default profile
sudo mkdir /root/.config/powershell -p
sudo mv /common/Default_Profile.ps1 /root/.config/powershell/Microsoft.PowerShell_profile.ps1
sudo mkdir /root/powershell/Data -p

#Tar OliveTin Install
printf "\n\n$(date)-Setting up OliveTin\n"
sudo wget https://github.com/OliveTin/OliveTin/releases/download/2023.03.25/OliveTin-linux-amd64.tar.gz -O /tmp/OliveTin-linux-amd64.tar.gz
sudo tar -xf /tmp/OliveTin-linux-amd64.tar.gz -C /
sudo mkdir /var/www/ -p
sudo ln -s /OliveTin-linux-amd64/OliveTin /usr/local/bin/OliveTin
sudo ln -s /OliveTin-linux-amd64 /etc/OliveTin
sudo ln -s /OliveTin-linux-amd64/webui /var/www/olivetin

#Update OliveTin Configuration File
sudo rm /OliveTin-linux-amd64/config.yaml
sudo mv /common/configs/config.yaml /OliveTin-linux-amd64/config.yaml

#Update service file to use Ubuntu user and get it running
printf "\n\n$(date)-Configure OT to use OT user\n"
sudo chown -R root.root /OliveTin-linux-amd64/
sed -i '/^Restart=always.*/a User=root' /OliveTin-linux-amd64/OliveTin.service
sudo systemctl link /OliveTin-linux-amd64/OliveTin.service
sudo systemctl enable OliveTin.service

#Docker
printf "\n\n$(date)-Install Docker\n"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin openjdk-17-jre-headless

printf "\n\n$(date)-Grab and get containers running\n"
wget https://raw.githubusercontent.com/Graylog2/graylog-training-data/main/instruqt/common/configs/docker-compose-glservices.yml
wget https://raw.githubusercontent.com/Graylog2/graylog-training-data/main/instruqt/common/configs/graylog-training-changes.env
sudo docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env pull -q
sudo docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env create
sudo docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env up -d

#Wait for GL before changes
while ! curl -s -u 'admin:yabba dabba doo' http://localhost:9000/api/system/cluster/nodes; do
	printf "\n\nWaiting for GL to come online to add content\n"
    sleep 5
done

#Update Cluster ID
mongoc=$(sudo docker ps | grep mongo | awk '{print $1}')
sudo docker exec -i $mongoc /usr/bin/mongosh graylog --eval "db.cluster_config.updateMany({\"type\":\"org.graylog2.plugin.cluster.ClusterId\"}, {\$set:{payload:{cluster_id:\"$cluster_id\"}}});"

#Copy GeoIP DBs
glc=$(sudo docker ps | grep graylog-enterprise | awk '{print $1}')
sudo docker cp /common/geodb/GeoLite2-ASN.mmdb $glc:/usr/share/graylog/data/config/GeoLite2-ASN.mmdb
sudo sudo docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/GeoLite2-ASN.mmdb
sudo docker cp /common/geodb/GeoLite2-City.mmdb $glc:/usr/share/graylog/data/config/GeoLite2-City.mmdb
sudo sudo docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/GeoLite2-City.mmdb
sudo docker cp /common/geodb/GeoLite2-Country.mmdb $glc:/usr/share/graylog/data/config/GeoLite2-Country.mmdb
sudo sudo docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/GeoLite2-Country.mmdb

#Install Licenses
printf "\n\nAdding licenses\n"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/plugins/org.graylog.plugins.license/licenses" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "$license_enterprise"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/plugins/org.graylog.plugins.license/licenses" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "$license_security"
sleep 15s

#Training Customs
##Header Badge
printf "\n\nAdding Header Badge\n"
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/cluster_config/org.graylog.plugins.customization.HeaderBadge" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"badge_text":"TRAINING","badge_color":"#1a237e","badge_enable":true}'

#Greynoise Create Adaptor
printf "\n\nCreating greynoise Data Adaptor\n"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/lookup/adapters" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "{\"id\":null,\"title\":\"Greynoise Enterprise Full IP Lookup\",\"description\":\"Greynoise Enterprise Full IP Lookup\",\"name\":\"greynoise-enterprise-full-ip-lookup\",\"config\":{\"type\":\"GreyNoise Lookup [Enterprise]\",\"api_token\":{\"set_value\":\"$gn_api_key\"}}}"
#Graynoise Create Cache
printf "\n\nCreating greynoise cache\n"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/lookup/caches" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"id":null,"title":"Greynoise Enterprise Full IP Lookup-cache","description":"Greynoise Enterprise Full IP Lookup-cache","name":"greynoise-enterprise-full-ip-lookup-cache","config":{"type":"guava_cache","max_size":1000,"expire_after_access":60,"expire_after_access_unit":"SECONDS","expire_after_write":0,"expire_after_write_unit":null}}'
#Graynoise Create Lookup Table
printf "\n\nCreating greynoise lookup table\n"
gncache=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/system/lookup/caches?page=1&per_page=50&sort=title&order=desc&query=greynoise' | jq -r '.caches[].id')
gnda=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/system/lookup/adapters?page=1&per_page=50&sort=title&order=desc&query=Greynoise' | jq -r '.data_adapters[].id')
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/lookup/tables" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "{\"title\":\"Greynoise Enterprise Full IP Lookup Table\",\"description\":\"Greynoise Enterprise Full IP Lookup Table\",\"name\":\"greynoise-lookup\",\"default_single_value\":\"\",\"default_single_value_type\":\"NULL\",\"default_multi_value\":\"\",\"default_multi_value_type\":\"NULL\",\"data_adapter_id\":\"$gnda\",\"cache_id\":\"$gncache\"}"

#Creating Indices
printf "\n\ncreate General Desktop Events Index\n"
curl -u 'admin:yabba dabba doo' -XPOST 'http://localhost:9000/api/system/indices/index_sets' -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"title":"General Desktop Events","description":"General Desktop Events","index_prefix":"general-desktop","writable":true,"can_be_default":true,"shards":2,"replicas":0,"retention_strategy_class":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategy","retention_strategy":{"max_number_of_indices":3,"type":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategyConfig"},"index_analyzer":"standard","index_optimization_max_num_segments":1,"index_optimization_disabled":false,"field_type_refresh_interval":5000,"rotation_strategy_class":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategy","rotation_strategy":{"max_docs_per_index":20000,"type":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategyConfig"},"creation_date":"2022-08-17T21:06:47.393Z"}'
printf "\n\ncreate Training Index\n"
curl -u 'admin:yabba dabba doo' -XPOST 'http://localhost:9000/api/system/indices/index_sets' -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"title":"Training","description":"Training","index_prefix":"train","writable":true,"can_be_default":true,"shards":2,"replicas":0,"retention_strategy_class":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategy","retention_strategy":{"max_number_of_indices":3,"type":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategyConfig"},"index_analyzer":"standard","index_optimization_max_num_segments":1,"index_optimization_disabled":false,"field_type_refresh_interval":5000,"rotation_strategy_class":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategy","rotation_strategy":{"max_docs_per_index":20000,"type":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategyConfig"},"creation_date":"2022-08-17T21:06:47.393Z"}'

#BashRC
cat <<EOF >> /root/.bashrc
printf "\e[37m ██████╗ ██████╗  █████╗ ██╗   ██╗\e[31m██╗      ██████╗  ██████╗ \n";
printf "\e[37m██╔════╝ ██╔══██╗██╔══██╗╚██╗ ██╔╝\e[31m██║     ██╔═══██╗██╔════╝ \n";
printf "\e[37m██║  ███╗██████╔╝███████║ ╚████╔╝ \e[31m██║     ██║   ██║██║  ███╗\n";
printf "\e[37m██║   ██║██╔══██╗██╔══██║  ╚██╔╝  \e[31m██║     ██║   ██║██║   ██║\n";
printf "\e[37m╚██████╔╝██║  ██║██║  ██║   ██║   \e[31m███████╗╚██████╔╝╚██████╔╝\n";
printf "\e[37m ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   \e[31m╚══════╝ ╚═════╝  ╚═════╝ \n";
printf "                                                            \n";
printf "\e[39m Hi,\n Welcome to Graylog ${CLASS}\n\n";
printf "\e[93m Your public DNS record is:https://${_SANDBOX_ID}.logfather.org";
EOF
### END Base Config

printf "\n\n$(date)-Complete Base Setup -> Running class config\n"

#Class Config
printf "\n\n$(date)-Grab Class Data\n"
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/instruqt/$CLASS"

printf printf "\n\n$(date)-Move Class Data and make exec\n"
sudo mv $CLASS /$CLASS
sudo chmod +x /$CLASS/scripts/*.sh
sudo docker ps

printf "\n\n$(date)-Starting Class Config Script\n"
/$CLASS/scripts/config.sh

printf "\n\n$(date)-Complete. Locked and loaded\n"