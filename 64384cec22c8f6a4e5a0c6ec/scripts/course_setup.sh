# Securing Graylog Course setup script

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

# Set ownership+mode for /etc/graylog:
sudo chown graylog.graylog -R /etc/graylog
sudo chmod g+w -R /etc/graylog
# Add admin to graylog group
sudo usermod -aG graylog $LUSER

# Modify server.conf:
cp "/$STRIGO_CLASS_ID/configs/server.conf" /etc/graylog/server
sed -i "s/PUBLICDNS/$dns.logfather.org/" /etc/graylog/server/server.conf

# Modify opensearch.yml:
cp "/$STRIGO_CLASS_ID/configs/opensearch.yml" /etc/opensearch/
# sed -i "s/STRIGO_RESOURCE_1_DNS/$STRIGO_RESOURCE_1_DNS/" /etc/opensearch/opensearch.yml
cp "/$STRIGO_CLASS_ID/configs/jvm.options" /etc/opensearch/

# Set java path for use by Opensearch Security plugin:
echo "export OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk" >> /etc/profile

# Add mongodb node resolution:
echo "127.0.0.1 opensearch01.logfather.org" | sudo tee -a /etc/hosts

# Start services:
systemctl enable --now mongod.service graylog-server.service opensearch.service

# Import CSR generator script:
cp "/$STRIGO_CLASS_ID/scripts/generate_certs.sh" /home/$LUSER/generate_certs.sh
chmod +x /home/$LUSER/generate_certs.sh

# Minor vim behavior tweak to fix undesireable pasting behavior:
printf "set paste\nsource \$VIMRUNTIME/defaults.vim\n" > ~/.vimrc

# Create file for lab to finally appear
touch /home/$LUSER/gogogo