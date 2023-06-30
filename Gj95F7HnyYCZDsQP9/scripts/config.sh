#!/bin/bash
#load Vars from Strigo
source /etc/profile

echo "Running DNS Registration Steps" >> /home/ubuntu/strigosuccess
dnscount=0
DNSMatch=false
#Check for Existing DNS Record
echo "Checking for existing record, result:" >> /home/ubuntu/strigosuccess
DNSCheck=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records?type=CNAME&name=$dns.logfather.org&match=all" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" | jq -r '.result[]')
echo $DNSCheck >> /home/ubuntu/strigosuccess
if [ ! -z "$DNSCheck" ]; then
    #Check it's CName to see if it matches existing DNS Record
    echo "Checking if CNAME is the same, result:" >> /home/ubuntu/strigosuccess
    CName=$(echo $DNSCheck | jq -r '.content')
    echo "$CName vs $LAB" >> /home/ubuntu/strigosuccess
    if [[ ! "$CName" == "$LAB" ]]; then
        #No Match - new DNS record but also need to check for more numbers
        #Loop through numbers and check for existing  DNS Records
        echo "Not a match, looping to find unused DNS record" >> /home/ubuntu/strigosuccess
        until [[ -z "$DNSCheck" ]];
        do
            #Add one to dnscount and check if that record exists. This will loop until null OR a matched CName is found in cases of paused labs THIS causes issues so lets fix it!
            ((dnscount++))
            DNSCheck=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records?type=CNAME&name=$dns$dnscount.logfather.org&match=all" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" | jq -r '.result[]')
            CName=$(echo $DNSCheck | jq -r '.content')
            echo "Comparing new DNS record's CNAME (if there is one), result" >> /home/ubuntu/strigosuccess
            echo $CName >> /home/ubuntu/strigosuccess
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
    echo "Creating DNS Record for: $dns" >> /home/ubuntu/strigosuccess
    cdata="{\"type\":\"CNAME\",\"name\":\"$dns\",\"content\":\"$LAB\",\"ttl\":3600,\"priority\":10,\"proxied\":false}"
    createcname=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" --data $cdata)
    result=$(echo $createcname | jq '.success')
    echo "Result: $result" >> /home/ubuntu/strigosuccess
fi
echo $dns >> /home/ubuntu/DNSSuccess
echo "Registered DNS record: $dns"
echo "export dns=$dns" >> /etc/profile


###Cert Update
apt install git-svn -y
#Certs
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs"

## Copy Certs and Decode
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

keytool -import -trustcacerts -alias letsencryptcaroot  -file /etc/graylog/fullchain.pem -keystore /etc/graylog/cacerts -storepass changeit -noprompt

cp /etc/graylog/fullchain.pem /usr/local/share/ca-certificates/fullchain.crt
update-ca-certificates

#Wait for GL before changes
while ! curl -s -u 'admin:yabba dabba doo' http://localhost:9000/api/system/cluster/nodes; do
	printf "\n\nWaiting for GL to come online to add content\n"
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

#Update GL Docker Environment
echo "Removing old variables" >> /home/ubuntu/strigosuccess
sed -i '/GLEURI=/d' /etc/graylog/strigo-graylog-training-changes.env
sed -i '/GLBINDADDR=/d' /etc/graylog/strigo-graylog-training-changes.env
sed -i '/GLTLS=/d' /etc/graylog/strigo-graylog-training-changes.env

echo "Adding updated variables" >> /home/ubuntu/strigosuccess
echo "GLBINDADDR=\"0.0.0.0:443\"" >> /etc/graylog/strigo-graylog-training-changes.env
echo "GLTLS=true" >> /etc/graylog/strigo-graylog-training-changes.env
echo "GLEURI=https://$dns.logfather.org/" >> /etc/graylog/strigo-graylog-training-changes.env

#Post Hog API Key
sed -i '/^      GRAYLOG_SERVER_JAVA_OPTS: ${GLJAVAOPTS}.*/a\      GRAYLOG_TELEMETRY_API_KEY: "phc_8LAbITO87JuBOZXXGsKGdFH7HWNK585n0dMF1c4KlcF"' /etc/graylog/docker-compose-glservices.yml

#Launch Docker to load changes in env file
echo "Running Docker Compose to update GL environment with new information" >> /home/ubuntu/strigosuccess
docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d
pwsh -c 'write-host "loaded PS!"'