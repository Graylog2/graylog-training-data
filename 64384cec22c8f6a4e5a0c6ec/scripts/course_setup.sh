# Securing Graylog Course setup script

# Special cert setup section bc this class can't use the common certs.sh as-is and I cant put this in the generate_certs.sh bc the .pwd file for decoding the cert files is deleted in cleanup.sh and we don't want students seeing that super secret password and it's too close to the CTF launch to change the common certs so I'll get to it later ok geez:
#git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs" /.ssl
cd /.ssl
# Import & decode cert files:
for i in ./*.enc
do
    openssl enc -in $i -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > "${i%.enc}"
    echo "Decoded ${i%.pem.enc}"
done

# Add logfather.org cert chain to host CA trust store
# to avoid having to use -k flag in curl commands:
openssl x509 -inform PEM -in fullchain.pem -out /usr/local/share/ca-certificates/fullchain.crt
update-ca-certificates

# Delete unneded files:
rm /.ssl/*.enc /.ssl/cacerts /.ssl/root-ca.pem /.ssl/intermediate-ca.pem

# Create course motd banner:
source /etc/profile
cat <<EOF >> /home/$LUSER/.bashrc
printf "\e[37m ██████╗ ██████╗  █████╗ ██╗   ██╗\e[31m██╗      ██████╗  ██████╗ \n";
printf "\e[37m██╔════╝ ██╔══██╗██╔══██╗╚██╗ ██╔╝\e[31m██║     ██╔═══██╗██╔════╝ \n";
printf "\e[37m██║  ███╗██████╔╝███████║ ╚████╔╝ \e[31m██║     ██║   ██║██║  ███╗\n";
printf "\e[37m██║   ██║██╔══██╗██╔══██║  ╚██╔╝  \e[31m██║     ██║   ██║██║   ██║\n";
printf "\e[37m╚██████╔╝██║  ██║██║  ██║   ██║   \e[31m███████╗╚██████╔╝╚██████╔╝\n";
printf "\e[37m ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   \e[31m╚══════╝ ╚═════╝  ╚═════╝ \n";
printf "                                                            \n";
printf "\e[39m Hi ${STRIGO_USER_NAME},\n Welcome to ${STRIGO_CLASS_NAME}\n\n";
printf "\e[39m Your Graylog server can be reached at the following URL:\n\n"
printf "\t\e[93mhttp://$dns.logfather.org:9000/\n\n\e[39m";

PATH=$PATH:/usr/share/graylog-server/jvm/bin
EOF

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
cp "/$STRIGO_CLASS_ID/configs/server.conf" /etc/graylog/server
sed -i "s/PUBLICDNS/$dns.logfather.org/" /etc/graylog/server/server.conf

# Modify opensearch.yml:
cp "/$STRIGO_CLASS_ID/configs/opensearch.yml" /etc/opensearch/
# sed -i "s/STRIGO_RESOURCE_1_DNS/$STRIGO_RESOURCE_1_DNS/" /etc/opensearch/opensearch.yml
cp "/$STRIGO_CLASS_ID/configs/jvm.options" /etc/opensearch/

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

# Wait for Graylog web to be available before creating Input:
until curl -s localhost:9000
do
    echo "Waiting for Graylog API to come online..."
    sleep 1
done > /dev/null

# Create Inputs:
curl -k -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.gelf.http.GELFHttpInput","configuration":{"bind_address":"0.0.0.0","port":12201,"recv_buffer_size":1048576,"number_worker_threads":1,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"enable_bulk_receiving":false,"enable_cors":true,"max_http_chunk_size":65536,"idle_writer_timeout":60,"override_source":null,"charset_name":"UTF-8","decompress_size_limit":8388608},"title":"GELF HTTP","global":true}'

# Delete demo files:
rm /etc/opensearch/*.pem

# Import CSR generator script:
cp "/$STRIGO_CLASS_ID/scripts/generate_certs.sh" /home/$LUSER/generate_certs.sh
chmod +x /home/$LUSER/generate_certs.sh

# Minor vim behavior tweak to fix undesireable pasting behavior:
printf "set paste\nsource \$VIMRUNTIME/defaults.vim\n" > ~/.vimrc

# Add keytool binary to sudo's secure_path so user can run command with sudo w/o specifying full path:
sed -E -i 's%secure_path="(.*?)"%secure_path="\1:/usr/share/graylog-server/jvm/bin"%' /etc/sudoers

# Add student CNAME to /etc/cloud/templates/hosts.debian.tmpl to prevent "Unable to call proxied resource" errors in server.log
# as well as allow apps to resolve this hostname after instance pause & resume:
echo "127.0.0.1 $dns.logfather.org" >> /etc/cloud/templates/hosts.debian.tmpl

# Create file for lab to finally appear
touch /home/$LUSER/gogogo