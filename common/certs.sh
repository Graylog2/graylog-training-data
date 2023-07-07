#!/bin/bash
#load Vars from Strigo
source /etc/profile

###Cert Update
echo "Grabbing Certs" >> /home/$LUSER/strigosuccess
apt install git-svn -y
#Certs
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs" >> /home/$LUSER/strigosuccess
echo "The present working directory is $(pwd)" >> /home/$LUSER/strigosuccess

## Copy Certs and Decode
echo "Decoding Certs" >> /home/$LUSER/strigosuccess
openssl enc -in /certs/privkey.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > /etc/graylog/privkey.pem
openssl enc -in /certs/cert.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > /etc/graylog/cert.pem
openssl enc -in /certs/fullchain.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > /etc/graylog/fullchain.pem
rm /.pwd
cp /certs/cacerts /etc/graylog/cacerts 

#Cert Permissions
chown root.root /etc/graylog/*.pem
chmod 600 /etc/graylog/*.pem

#Update OS and keystore with chain
#keytool -importcert -alias letsencryptca -file /etc/graylog/fullchain.pem -keystore /etc/graylog/cacerts -storepass changeit -noprompt

echo "Updating Keystore" >> /home/$LUSER/strigosuccess
keytool -import -trustcacerts -alias letsencryptcaroot  -file /etc/graylog/fullchain.pem -keystore /etc/graylog/cacerts -storepass changeit -noprompt >> /home/$LUSER/strigosuccess

cp /etc/graylog/fullchain.pem /usr/local/share/ca-certificates/fullchain.crt
update-ca-certificates

#Wait for GL before changes
if [ $(which docker) ]; then
    while ! curl -s -u 'admin:yabba dabba doo' http://localhost:9000/api/system/cluster/nodes; do
        printf "\n\nWaiting for GL to come online to add content\n" >> /home/$LUSER/strigosuccess
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

echo "Cert install complete!" >> /home/$LUSER/strigosuccess