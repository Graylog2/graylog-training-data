#!/bin/bash
#load Vars from Strigo
source /etc/profile

#Set useful scripts to the home directory
echo "Set symlinks" >> /home/$LUSER/strigosuccess
ln -s /$STRIGO_CLASS_ID/.scripts/node_install.sh /home/admin/node_install.sh
ln -s /$STRIGO_CLASS_ID/.scripts/cheat.sh /home/admin/cheat.sh

# Apply proper ownership
chown -R 1000:1000 /$STRIGO_CLASS_ID/

#echo "Grabbing common scripts" >> /home/$LUSER/strigosuccess
#apt install git-svn jq -y
#Certs
#git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/common" >> /home/$LUSER/strigosuccess
#chmod +x /common/*.sh


if [[ "$STRIGO_RESOURCE_NAME" == "Proxy" ]]; then
    ##Setup proxy
    echo "Setting up Proxy box" >> /home/$LUSER/strigosuccess
    #Install OT
    wget https://github.com/OliveTin/OliveTin/releases/download/2023.03.25/OliveTin_linux_amd64.deb
    sudo dpkg -i OliveTin_linux_amd64.deb
    sudo systemctl start OliveTin.service
    sudo systemctl enable OliveTin.service
    mkdir -p /etc/OliveTin; ln -s /$STRIGO_CLASS_ID/.configs/config.yaml /etc/OliveTin

    #DNS
    ./common/dns.sh >> /home/$LUSER/strigosuccess
    #Update DNS file
    source /etc/profile
    echo "${dns}.logfather.org" > /home/$LUSER/DNSSuccess
    
    ## Setting up Traefik Environment Variable overrides
    # Create Service override (service isn't installed yet)
    mkdir -p /etc/systemd/system/traefik.service.d
    
    # Add the file
    cat <<EOF >> /etc/systemd/system/traefik.service.d/override.conf
    [Service]
    Environment="STRIGO_PUBLIC_DNS=$dns.logfather.org"
    Environment="STRIGO_RESOURCE_0_DNS=$STRIGO_RESOURCE_0_DNS"
    Environment="STRIGO_RESOURCE_1_DNS=$STRIGO_RESOURCE_1_DNS"
    Environment="STRIGO_RESOURCE_2_DNS=$STRIGO_RESOURCE_2_DNS"
    Environment="STRIGO_RESOURCE_3_DNS=$STRIGO_RESOURCE_3_DNS"
    
EOF

    # Install Traefik
    echo "Installing Traefik" >> /home/$LUSER/strigosuccess
    sudo apt-get install wget -y
    wget https://github.com/traefik/traefik/releases/download/v2.10.1/traefik_v2.10.1_linux_amd64.tar.gz -P /tmp/
    tar -xzvf /tmp/traefik_v2.10.1_linux_amd64.tar.gz
    chmod +x /tmp/traefik
    mv traefik /usr/local/bin/traefik
    sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/traefik
    sudo groupadd -g 321 traefik
    sudo useradd \
    -g traefik --no-user-group \
    --home-dir /var/www --no-create-home \
    --shell /usr/sbin/nologin \
    --system --uid 321 traefik

    ## Setup directories and Permissions
    sudo mkdir -p /etc/traefik/acme
    sudo mkdir -p /etc/traefik/certs
    sudo mkdir -p /var/log/traefik
    sudo chown -R traefik:traefik /var/log/traefik

    #Certs
    #echo "Grabbing Certs" >> /home/$LUSER/strigosuccess
    #apt install git-svn -y
    #git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs"

    ## Copy Certs and Decode
    sudo openssl enc -in /certs/privkey.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:.pwd > /etc/traefik/certs/privkey.pem
    sudo openssl enc -in /certs/cert.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:.pwd > /etc/traefik/certs/cert.pem
    sudo openssl enc -in /certs/fullchain.pem.enc -aes-256-cbc -pbkdf2 -d -pass file:.pwd > /etc/traefik/certs/fullchain.pem
    rm .pwd
    
    ## copy configs
    sudo cp /$STRIGO_CLASS_ID/.configs/traefik*.yml /etc/traefik/
    sudo chown -R traefik:traefik /etc/traefik/
    sudo chmod 644 /etc/traefik/traefik.yml

    ## copy traefik service file once created
    echo "updating and starting Traefik" >> /home/$LUSER/strigosuccess
    sudo cp /$STRIGO_CLASS_ID/.configs/traefik.service /etc/systemd/system/
    sudo chown root:root /etc/systemd/system/traefik.service
    sudo chmod 644 /etc/systemd/system/traefik.service

    sudo systemctl daemon-reload
    sudo systemctl start traefik.service
    sudo systemctl enable traefik.service

else
    #Setup non-proxy
    echo "Not the proxy box running (if) any node steps" >> /home/$LUSER/strigosuccess
fi

#OT Theme IF we use it
#./common/ot_gl_theme.sh >> /home/$LUSER/strigosuccess

sed -i '/export apitoken=/d' /etc/profile
sed -i '/export authemail=/d' /etc/profile
rm -r /certs

echo "Complete!" >> /home/$LUSER/strigosuccess