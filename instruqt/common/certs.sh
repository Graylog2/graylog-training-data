#!/bin/bash
#load Vars from Strigo
source /etc/profile

# Skip execution for TLS course:
if [[ "$CLASS" == "64384cec22c8f6a4e5a0c6ec" ]]; then
  echo "Skipping execution of $(basename "$0") because this is the TLS course..." 
  exit
fi

# Make /etc/graylog dir if doesn't exist (e.g. non-Dan-AMI classes):
if [ ! -d /etc/graylog ]; then
  mkdir /etc/graylog
fi

# Import certs:
echo "Grabbing Certs" 
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs" 
echo "The present working directory is $(pwd)" 

## Copy Certs and Decode
echo "Decoding Certs" 
openssl enc -in /certs/privkey.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > /etc/graylog/privkey.pem
openssl enc -in /certs/cert.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > /etc/graylog/cert.pem
openssl enc -in /certs/fullchain.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > /etc/graylog/fullchain.pem
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
if [ $(which docker) ]; then
    while ! curl -s -u 'admin:yabba dabba doo' http://localhost:9000/api/system/cluster/nodes; do
        printf "\n\nWaiting for GL to come online to add certs\n" 
        sleep 5
    done

    ## Update Docker Container with certs
    glc=$(sudo docker ps | grep graylog-enterprise | awk '{print $1}')
    docker cp /etc/graylog/cert.pem $glc:/usr/share/graylog/data/config/cert.pem
    docker cp /etc/graylog/privkey.pem $glc:/usr/share/graylog/data/config/privkey.pem
    docker cp /etc/graylog/fullchain.pem $glc:/usr/share/graylog/data/config/fullchain.pem
    docker cp /etc/graylog/cacerts $glc:/usr/share/graylog/data/config/cacerts

    docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/cert.pem
    docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/privkey.pem
    docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/fullchain.pem
    docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/cacerts
fi

echo "Cert install complete!" 