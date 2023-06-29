# Securing Graylog with TLS Course setup script

# Ensure base OS is up to date:
apt update && apt upgrade

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

### Install Opensearch:
# Download GPG key:
curl -fsSL https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg -o /etc/apt/trusted.gpg.d/opensearch.gpg --dearmor > /dev/null
# Add repo:
echo "deb [signed-by=/etc/apt/trusted.gpg.d/opensearch.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | tee -a /etc/apt/sources.list.d/opensearch-2.x.list > /dev/null

# Install GL stack:
apt update && apt install -y mongodb-org graylog-enterprise opensearch

# Modify server.conf:
cp "/Securing Graylog with TLS/configs/server.conf" /etc/graylog/server
sed -i "s/PUBLICDNS/$publicdns/" /etc/graylog/server/server.conf
sed -i "s/PUBLICDNS_OS/$publicdns_os/" /etc/graylog/server/server.conf

# # Modify opensearch.yml:
# cp "/Securing Graylog with TLS/configs/opensearch.yml" /etc/opensearch/
# sed -i "s/STRIGO_RESOURCE_1_DNS/$STRIGO_RESOURCE_1_DNS/" /etc/opensearch/opensearch.yml

# Set java path for use by Opensearch Security plugin:
echo "export JAVA_HOME=/usr/share/opensearch/jdk" >> /etc/profile

# Add mongodb node resolution:
echo "127.0.0.1 $publicdns_mg" >> /etc/hosts
echo "127.0.0.1 $publicdns_os" >> /etc/hosts

# Start services:
systemctl enable --now mongod.service graylog-server.service opensearch.service

# Import CSR generator script:
cp "/Securing Graylog with TLS/scripts/generate-csrs.sh" /home/admin/generate-csrs.sh

# Cleanup:
rm -rf "/Securing Graylog with TLS"