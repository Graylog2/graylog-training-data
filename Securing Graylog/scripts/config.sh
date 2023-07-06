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
sudo usermod -aG graylog admin

# Modify server.conf:
cp "/Securing Graylog/configs/server.conf" /etc/graylog/server
sed -i "s/PUBLICDNS_GL/$publicdns/" /etc/graylog/server/server.conf
sed -i "s/PUBLICDNS_OS/$dns_os/" /etc/graylog/server/server.conf

# Modify opensearch.yml:
cp "/Securing Graylog/configs/opensearch.yml" /etc/opensearch/
# sed -i "s/STRIGO_RESOURCE_1_DNS/$STRIGO_RESOURCE_1_DNS/" /etc/opensearch/opensearch.yml
cp "/Securing Graylog/configs/jvm.options" /etc/opensearch/

# Set java path for use by Opensearch Security plugin:
echo "export OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk" >> /etc/profile

# Add mongodb node resolution:
echo "127.0.0.1 $dns_os" | sudo tee -a /etc/hosts

# Start services:
systemctl enable --now mongod.service graylog-server.service opensearch.service

# Import CSR generator script:
cp "/Securing Graylog/scripts/generate-csrs.sh" /home/admin/generate-csrs.sh
chmod +x /home/admin/generate-csrs.sh

# Import certs & keys to /certs:
sudo git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs" /certs
for i in /certs/*.enc
do
    sudo openssl enc -in $i -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > "${i%.enc}"
done

# Minor vim behavior tweak to fix undesireable pasting behavior:
printf "set paste\nsource \$VIMRUNTIME/defaults.vim\n" > ~/.vimrc

# Cleanup corse content & create file for lab to finally appear
sudo rm -rf "/Securing Graylog" /certs/*.enc /.pwd
touch /home/admin/gogogo