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

### Install MongoDB repo:
# Download GPG key:
curl -fsSL https://pgp.mongodb.com/server-$MONGODB_VERSION.asc | gpg -o /etc/apt/trusted.gpg.d/mongodb-server-$MONGODB_VERSION.gpg --dearmor > /dev/null
# Add repo:
echo "deb [ arch=amd64 signed-by=/etc/apt/trusted.gpg.d/mongodb-server-$MONGODB_VERSION.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/$MONGODB_VERSION multiverse" | tee /etc/apt/sources.list.d/mongodb-org-$MONGODB_VERSION.list

### Install Graylog repo:
wget https://packages.graylog2.org/repo/packages/graylog-$GRAYLOG_VERSION-repository_latest.deb
dpkg -i graylog-$GRAYLOG_VERSION-repository_latest.deb
rm graylog-$GRAYLOG_VERSION-repository_latest.deb

# Install GL stack:
apt-get update && apt-get install -y mongodb-org graylog-enterprise graylog-datanode

# Set ownership+mode for /etc/graylog:
# chown graylog.graylog -R /etc/graylog
# chmod g+w -R /etc/graylog

# Import common Graylog config needed for first service start:
cp /common/configs/server.conf /etc/graylog/server/
sed -i "s/PUBLICDNS/$dns.logfather.org/" /etc/graylog/server/server.conf

# Start services:
systemctl enable --now mongod.service graylog-datanode.service graylog-server.service

# Wait for OpenSearch to be accessible before continuing
# while ! curl -s localhost:9200
# do
#     echo "Waiting for Opensearch API to come online before launching Graylog..."
#     sleep 5
# done

# systemctl enable --now graylog-server.service
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