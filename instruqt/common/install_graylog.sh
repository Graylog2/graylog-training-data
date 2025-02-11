#!/bin/bash

# Install Graylog, MongoDB, and Opensearch
# Only needed if using a non-Docker environment!
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile
GRAYLOG_VERSION="6.1"
MONGODB_VERSION="6.0"
OPENSEARCH_VERSION="2.15.0"

### Install MongoDB:
# Download GPG key:
curl -fsSL https://pgp.mongodb.com/server-$MONGODB_VERSION.asc | gpg -o /etc/apt/trusted.gpg.d/mongodb-server-$MONGODB_VERSION.gpg --dearmor > /dev/null
# Add repo:
echo "deb [ arch=amd64 signed-by=/etc/apt/trusted.gpg.d/mongodb-server-$MONGODB_VERSION.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/$MONGODB_VERSION multiverse" | tee /etc/apt/sources.list.d/mongodb-org-$MONGODB_VERSION.list

### Install Graylog:
wget https://packages.graylog2.org/repo/packages/graylog-$GRAYLOG_VERSION-repository_latest.deb
dpkg -i graylog-$GRAYLOG_VERSION-repository_latest.deb
rm graylog-$GRAYLOG_VERSION-repository_latest.deb

### Install Opensearch:
# Download GPG key:
curl -fsSL https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg -o /etc/apt/trusted.gpg.d/opensearch.gpg --dearmor > /dev/null
# Add repo:
echo "deb [signed-by=/etc/apt/trusted.gpg.d/opensearch.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | tee -a /etc/apt/sources.list.d/opensearch-2.x.list > /dev/null

# Install GL stack:
apt-get update && apt-get install -y mongodb-org graylog-enterprise opensearch=$OPENSEARCH_VERSION

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