#!/bin/bash

# Install and configure Graylog in a Docker environment

# Avoids warnings during package installations
export DEBIAN_FRONTEND=noninteractive
# Import env vars used throughout scripts runtime
source /etc/profile

# Set up Docker repo
printf "\n\n$(date)-Adding Docker gpg key\n"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
printf "\n\n$(date)-Adding Docker repo to apt sources list\n"
printf "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

# Install Docker
printf "\n\n$(date)-Install Docker\n"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin openjdk-17-jre-headless

# Import Docker Compose config and start Graylog enviroment
printf "\n\n$(date)-Grab and get containers running\n"
wget https://raw.githubusercontent.com/Graylog2/graylog-training-data/main/instruqt/common/configs/docker-compose-glservices.yml
wget https://raw.githubusercontent.com/Graylog2/graylog-training-data/main/instruqt/common/configs/graylog-training-changes.env
sudo docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env pull -q
sudo docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env create
sudo docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env up -d

# Wait for Graylog to be accessible before continuing
while ! curl -s -u 'admin:yabba dabba doo' http://localhost:9000/api/system/cluster/nodes; do
	printf "\n\nWaiting for Graylog to come online...\n"
    sleep 5
done

# Update Cluster ID
mongoc=$(sudo docker ps | grep mongo | awk '{print $1}')
sudo docker exec -i $mongoc /usr/bin/mongosh graylog --eval "db.cluster_config.updateMany({\"type\":\"org.graylog2.plugin.cluster.ClusterId\"}, {\$set:{payload:{cluster_id:\"$cluster_id\"}}});"