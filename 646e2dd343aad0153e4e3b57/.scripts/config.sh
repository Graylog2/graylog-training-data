#!/bin/bash
source /etc/profile

#Set useful scripts to the home directory
ln -s /$STRIGO_CLASS_ID/.scripts/node_install.sh /home/admin/node_install.sh
ln -s /$STRIGO_CLASS_ID/.scripts/cheat.sh /home/admin/cheat.sh

# Apply proper ownership
chown -R 1000:1000 /$STRIGO_CLASS_ID/


if [[ -z "$dns" ]]; then
    ##Setup proxy
    echo "Setting up Proxy box" >> /root/logfather.dns.log
    #Install OT
    wget https://github.com/OliveTin/OliveTin/releases/download/2023.03.25/OliveTin_linux_amd64.deb
    sudo dpkg -i OliveTin_linux_amd64.deb 
    sudo systemctl start OliveTin.service 
    sudo systemctl enable OliveTin.service
    mkdir -p /etc/OliveTin; ln -s /$STRIGO_CLASS_ID/.configs/config.yaml /etc/OliveTin

    # DNS Shenanigans
    echo "Running DNS Registration Steps" >> /root/logfather.dns.log
    dnscount=0
    DNSMatch=false
    apt-get install jq -y
    #Check for Existing DNS Record
    echo "Checking for existing record, result:" >> /root/logfather.dns.log
    DNSCheck=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records?type=CNAME&name=$dns.logfather.org&match=all" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" | jq -r '.result[]')
    echo $DNSCheck >> /root/logfather.dns.log
    if [ ! -z "$DNSCheck" ]; then
        #Check it's CName to see if it matches existing DNS Record
        echo "Checking if CNAME is the same, result:" >> /root/logfather.dns.log
        CName=$(echo $DNSCheck | jq -r '.content')
        echo "$CName vs $LAB" >> /root/logfather.dns.log
        if [[ ! "$CName" == "$LAB" ]]; then
            #No Match - new DNS record but also need to check for more numbers
            #Loop through numbers and check for existing  DNS Records
            echo "Not a match, looping to find unused DNS record" >> /root/logfather.dns.log
            until [[ -z "$DNSCheck" ]];
            do
                #Add one to dnscount and check if that record exists. This will loop until null OR a matched CName is found in cases of paused labs THIS causes issues so lets fix it!
                ((dnscount++))
                DNSCheck=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records?type=CNAME&name=$dns$dnscount.logfather.org&match=all" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" | jq -r '.result[]')
                CName=$(echo $DNSCheck | jq -r '.content')
                echo "Comparing new DNS record's CNAME (if there is one), result" >> /root/logfather.dns.log
                echo $CName >> /root/logfather.dns.log
                if [[ "$CName" == "$LAB" ]]; then
                    echo "$CName compared to $LAB is true..." 
                    #If these match, ever, at all, exit the loop and set the DNS record below
                    DNSMatch="true"
                    break
                fi
            done
        fi
    fi
    #ONLY Update DNS Name IF there IS a count. Otherwise everyone is a zero. We don't like that.
    if [ $dnscount -gt 0 ]; then
        dns="$dns$dnscount"
    fi

    #Only create a new DNS record if there isn't one already with a matching CName
    if [[ ! "$DNSMatch" == "true" ]]; then
        #Create DNS Record
        echo "Creating DNS Record for: $dns" >> /root/logfather.dns.log
        cdata="{\"type\":\"CNAME\",\"name\":\"$dns\",\"content\":\"$LAB\",\"ttl\":3600,\"priority\":10,\"proxied\":false}"
        createcname=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" --data $cdata)
        result=$(echo $createcname | jq '.success')
        echo "Result: $result" >> /root/logfather.dns.log       
    fi
    echo "${dns}.logfather.org" >> /home/admin/publicdns
    echo "Registered DNS record: $dns"
    echo "export dns=$dns" >> /etc/profile
    echo "export STRIGO_PUBLIC_DNS=${dns}.logfather.org" >> /etc/profile
    echo "Adding updated variables" >> /root/logfather.dns.log

    ## Setting up Traefik Environment Variable overrides
    # Create Service override (service isn't installed yet)
    mkdir -p /etc/systemd/system/traefik.service.d
    
    # Add the file
    cat <<EOF >> /etc/systemd/system/traefik.service.d/override.conf
    [Service]
    Environment="STRIGO_PUBLIC_DNS=$STRIGO_PUBLIC_DNS"
    Environment="STRIGO_RESOURCE_0_DNS={{ .STRIGO_RESOURCE_0_DNS }}"
    Environment="STRIGO_RESOURCE_1_DNS={{ .STRIGO_RESOURCE_1_DNS }}"
    Environment="STRIGO_RESOURCE_2_DNS={{ .STRIGO_RESOURCE_2_DNS }}"
    Environment="STRIGO_RESOURCE_3_DNS={{ .STRIGO_RESOURCE_3_DNS }}"
EOF

    # Install Traefik
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
    apt install git-svn -y
    git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs"

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
    sudo cp /$STRIGO_CLASS_ID/.configs/traefik.service /etc/systemd/system/
    sudo chown root:root /etc/systemd/system/traefik.service
    sudo chmod 644 /etc/systemd/system/traefik.service

    sudo systemctl daemon-reload
    sudo systemctl start traefik.service
    sudo systemctl enable traefik.service

else
    #Setup non-proxy  
fi

#Cleanup
sed -i '/export apitoken=/d' /etc/profile
sed -i '/export authemail=/d' /etc/profile
rm -r /certs
