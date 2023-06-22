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
sed -i  's/^
touch /var/log/thelastquestion.log
echo 'printf "You found the right system, here is a flag: CosmicACOneDay!\n"' >> /root/.bashrc
(crontab -l 2>/dev/null; echo */1 \* \* \* \* echo \'RG91Z1RoZUdpZ2FudGljUGlwZXI=\' \>\> /var/log/thelastquestion.log) | crontab -
