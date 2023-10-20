#!/bin/bash

# Install Graylog, MongoDB, and Opensearch
# Only needed if using a non-Docker environment!

# Setup GPG keyring:
apt install -y gnupg

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
apt update && apt install -y mongodb-org graylog-enterprise opensearch

# Set ownership+mode for /etc/graylog:
sudo chown graylog.graylog -R /etc/graylog
sudo chmod g+w -R /etc/graylog
# Add admin to graylog group
sudo usermod -aG graylog $LUSER

# Modify server.conf:
cp "/$CLASS/configs/server.conf" /etc/graylog/server
sed -i "s/PUBLICDNS/$dns.logfather.org/" /etc/graylog/server/server.conf

# Modify opensearch.yml:
cp "/$CLASS/configs/opensearch.yml" /etc/opensearch/
# sed -i "s/STRIGO_RESOURCE_1_DNS/$STRIGO_RESOURCE_1_DNS/" /etc/opensearch/opensearch.yml
cp "/$CLASS/configs/jvm.options" /etc/opensearch/

# Set java path for use by Opensearch Security plugin:
echo "export OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk" >> /etc/profile

# Start services:
systemctl enable --now mongod.service opensearch.service
echo "Waiting for Opensearch service to be ready before launching Graylog..." 
until curl -s localhost:9200 
do
    echo "Waiting for Opensearch API to come online..."
    sleep 1
done > /dev/null
systemctl enable --now graylog-server.service

# Wait for Graylog web to be available:
until curl -s localhost:9000
do
    echo "Waiting for Graylog API to come online..."
    sleep 1
done > /dev/null

# Add keytool binary to sudo's secure_path so user can run command with sudo w/o specifying full path:
sed -E -i 's%secure_path="(.*?)"%secure_path="\1:/usr/share/graylog-server/jvm/bin"%' /etc/sudoers

# Minor vim behavior tweak to fix undesireable pasting behavior:
printf "set paste\nsource \$VIMRUNTIME/defaults.vim\n" > ~/.vimrc