apt-get update
apt-get install -y wget
wget https://packages.graylog2.org/repo/packages/graylog-sidecar-repository_1-5_all.deb
dpkg -i graylog-sidecar-repository_1-5_all.deb
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo tee -a /etc/apt/trusted.gpg.d/elasticsearch.asc
echo "deb https://artifacts.elastic.co/packages/oss-8.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-8.x.list
apt-get update
apt-get install -y openssh-server
apt-get install -y graylog-sidecar
apt-get install -y filebeat
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart ssh
echo 'root:AlexanderAdell' | chpasswd
sed -i '1s/^/\n/' /etc/graylog/sidecar/sidecar.yml
sed -i '1s/^/#Have a flag: oN-a-sPace-sHip-tO-X-23\n/' /etc/graylog/sidecar/sidecar.yml
sed -i '1s/^/#Who can remember all these config file names? I guess since you figured it out you can\n/' /etc/graylog/sidecar/sidecar.yml
sed -i 's/^#tls_skip_verify: false/tls_skip_verify: true/' /etc/graylog/sidecar/sidecar.yml
sed -i 's|^#server_url: "http://127.0.0.1:9000/api/"|server_url: "https://graylog:443/api/"|' /etc/graylog/sidecar/sidecar.yml
sed -i 's/server_api_token: ""/#server_api_token: "ZZZZZTOKENTOKENZZZZZ"/' /etc/graylog/sidecar/sidecar.yml
graylog-sidecar -service install
touch /var/log/thelastquestion.log
echo 'printf "You found the right system, here is a flag: CosmicACOneDay!\n"' >> /root/.bashrc
(crontab -l 2>/dev/null; echo */1 \* \* \* \* echo \'RG91Z1RoZUdpZ2FudGljUGlwZXI=\' \>\> /var/log/thelastquestion.log) | crontab -
