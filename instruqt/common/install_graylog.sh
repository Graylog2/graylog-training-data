#!/bin/bash

# Install Graylog, MongoDB, and Opensearch
# Only needed if using a non-Docker environment!

# Avoids warnings during package installations
export DEBIAN_FRONTEND=noninteractive
# Import env vars used throughout scripts runtime
source /etc/profile

### Install MongoDB:
# Download GPG key:
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | gpg -o /etc/apt/trusted.gpg.d/mongodb-server-6.0.gpg --dearmor > /dev/null
# Add repo:
echo "deb [signed-by=/etc/apt/trusted.gpg.d/mongodb-server-6.0.gpg] http://repo.mongodb.org/apt/debian bullseye/mongodb-org/6.0 main" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list

### Install Graylog:
wget https://packages.graylog2.org/repo/packages/graylog-5.1-repository_latest.deb
dpkg -i graylog-5.1-repository_latest.deb
rm graylog-5.1-repository_latest.deb

### Install Opensearch:
# Download GPG key:
curl -fsSL https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg -o /etc/apt/trusted.gpg.d/opensearch.gpg --dearmor > /dev/null
# Add repo:
echo "deb [signed-by=/etc/apt/trusted.gpg.d/opensearch.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | tee -a /etc/apt/sources.list.d/opensearch-2.x.list > /dev/null

# Install GL stack:
apt-get update && apt-get install -y mongodb-org graylog-enterprise opensearch=2.10.0

# Set ownership+mode for /etc/graylog:
chown graylog.graylog -R /etc/graylog
chmod g+w -R /etc/graylog

# Import common OpenSearch config needed for first service start:
cp /common/configs/opensearch.yml /common/configs/jvm.options /etc/opensearch

# Import common Graylog config needed for first service start:
cp /common/configs/server.conf /etc/graylog/server/

# Set java path for use by Opensearch Security plugin:
echo "export OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk" >> /etc/profile

# Start services:
systemctl enable --now mongod.service opensearch.service

# Wait for OpenSearch to be accessible before continuing
while ! curl -s localhost:9200
do
    echo "Waiting for Opensearch API to come online before launching Graylog..."
    sleep 5
done

systemctl enable --now graylog-server.service
# Wait for Graylog to be accessible before continuing
while ! curl -s http://localhost:9000/api; do
	printf "\n\nWaiting for Graylog to come online...\n"
    sleep 5
done

# Set Graylog Cluster ID:
/usr/bin/mongosh graylog --eval "db.cluster_config.updateMany({\"type\":\"org.graylog2.plugin.cluster.ClusterId\"}, {\$set:{payload:{cluster_id:\"$cluster_id\"}}});"

# Add keytool binary to sudo's secure_path so user can run command with sudo w/o specifying full path:
sed -E -i 's%secure_path="(.*?)"%secure_path="\1:/usr/share/graylog-server/jvm/bin"%' /etc/sudoers

# Add bundled keytool binary to path:
echo "PATH=$PATH:/usr/share/graylog-server/jvm/bin" >> /etc/profile