# Install Mongo

wget -qO- https://pgp.mongodb.com/server-6.0.asc | sudo tee -a /etc/apt/trusted.gpg.d/mongodb-server-6.0.asc
echo "deb http://repo.mongodb.org/apt/debian bullseye/mongodb-org/6.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update

sudo apt-get install -y mongodb-org

sudo systemctl daemon-reload
sudo systemctl enable mongod.service
#sudo systemctl restart mongod.service
#sudo systemctl --type=service --state=active | grep mongod

wget -qO- https://artifacts.opensearch.org/publickeys/opensearch.pgp | sudo tee -a /etc/apt/trusted.gpg.d/opensearch.asc
echo "deb https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/opensearch-2.x.list

sudo apt-get update
sudo apt-get install opensearch=2.5.0

sudo sysctl -w vm.max_map_count=262144

echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf

sudo systemctl daemon-reload
sudo systemctl enable opensearch.service
#sudo systemctl start opensearch.service

wget https://packages.graylog2.org/repo/packages/graylog-5.1-repository_latest.deb
sudo dpkg -i graylog-5.1-repository_latest.deb
sudo apt-get update -y
sudo apt-get install graylog-enterprise

sudo systemctl daemon-reload
sudo systemctl enable graylog-server
#sudo systemctl start graylog-server
sudo systemctl --type=service --state=active | grep graylog


## Copy the config, THEN start the services
# Configure JVM.Options as well for both GL and OS
# Total should be 50% of system

#sudo systemctl start opensearch.service
#sudo systemctl start graylog-server
