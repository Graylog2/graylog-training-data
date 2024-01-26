#!/bin/bash

# Install TLS certificates from repo for both Docker and non-Docker envs
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

# Make /etc/graylog dir if doesn't exist (e.g. Docker-base envs):
if [ ! -d /etc/graylog ]; then
  mkdir /etc/graylog
fi

# Import certs:
#echo "Grabbing Certs" 
#git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs" /certs

## Copy Certs and Decode
echo "Decoding Certs" 
openssl enc -in /certs/privkey.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/root/.pwd > /etc/graylog/privkey.pem
openssl enc -in /certs/cert.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/root/.pwd > /etc/graylog/cert.pem
openssl enc -in /certs/fullchain.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/root/.pwd > /etc/graylog/fullchain.pem
cp /certs/cacerts /etc/graylog/cacerts

#Cert Permissions
chown root.root /etc/graylog/*.pem
chmod 600 /etc/graylog/*.pem

#Update OS and keystore with chain
echo "Updating Keystore" 
keytool -import -trustcacerts -alias letsencryptcaroot  -file /etc/graylog/fullchain.pem -keystore /etc/graylog/cacerts -storepass changeit -noprompt 

cp /etc/graylog/fullchain.pem /usr/local/share/ca-certificates/fullchain.crt
update-ca-certificates

#Wait for GL before changes
while ! curl -s -u 'admin:yabba dabba doo' http://localhost:9000/api/system/cluster/nodes; do
  printf "\n\nWaiting for GL to come online to add certs\n" 
  sleep 5
done

## Update Docker Container with certs
printf "Copying certs into container"
glc=$(docker ps | grep graylog-enterprise | awk '{print $1}')
docker cp /etc/graylog/cert.pem $glc:/usr/share/graylog/data/config/cert.pem
docker cp /etc/graylog/privkey.pem $glc:/usr/share/graylog/data/config/privkey.pem
docker cp /etc/graylog/fullchain.pem $glc:/usr/share/graylog/data/config/fullchain.pem
docker cp /etc/graylog/cacerts $glc:/usr/share/graylog/data/config/cacerts

printf "Correcting permissions on cert in container"
docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/cert.pem
docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/privkey.pem
docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/fullchain.pem
docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/cacerts

echo "Cert install complete!" 