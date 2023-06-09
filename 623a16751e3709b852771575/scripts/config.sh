#!/bin/bash
#load Vars from Strigo
source /etc/profile

echo "Sleeping for random time up to 30 seconds to prevent DNS records from being over-written in cases of multiple labs starting at once" >> /home/ubuntu/strigosuccess
sleep $(( ( RANDOM % 30 )  + 1 ))

echo "The present working directory is $(pwd)" >> /home/ubuntu/strigosuccess
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
echo "Registered DNS record: $dns" >> /home/ubuntu/strigosuccess
sed -i '/export dns=/d' /etc/profile
echo "export dns=$dns" >> /etc/profile


###Cert Update
echo "Grabbing Certs" >> /home/ubuntu/strigosuccess
apt install git-svn -y
#Certs
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs" >> /home/ubuntu/strigosuccess
echo "The present working directory is $(pwd)" >> /home/ubuntu/strigosuccess

## Copy Certs and Decode
echo "Decoding Certs" >> /home/ubuntu/strigosuccess
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

echo "Updating Keystore" >> /home/ubuntu/strigosuccess
keytool -import -trustcacerts -alias letsencryptcaroot  -file /etc/graylog/fullchain.pem -keystore /etc/graylog/cacerts -storepass changeit -noprompt >> /home/ubuntu/strigosuccess

cp /etc/graylog/fullchain.pem /usr/local/share/ca-certificates/fullchain.crt
update-ca-certificates

#Wait for GL before changes
while ! curl -s -u 'admin:yabba dabba doo' http://localhost:9000/api/system/cluster/nodes; do
	printf "\n\nWaiting for GL to come online to add content\n" >> /home/ubuntu/strigosuccess
    sleep 5
done

#Setup Illuminate using API
printf "\n\nInstalling Illuminate" >> /home/ubuntu/strigosuccess
ilver=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/plugins/org.graylog.plugins.illuminate/bundles/hub/latest' | jq -r '.version')
printf "\n\nFound Illuminate Version:$ilver\n" >> /home/ubuntu/strigosuccess
ilinst=$(curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/plugins/org.graylog.plugins.illuminate/bundles/hub/$ilver" -H 'X-Requested-By: PS_TeamAwesome')
printf "\n\nDownload Version $ilver - result: $ilinst\n" >> /home/ubuntu/strigosuccess
bunact=$(curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/plugins/org.graylog.plugins.illuminate/bundles/$ilver" -H 'X-Requested-By: PS_TeamAwesome')
printf "\n\nInstallation Result: $bunact\n" >> /home/ubuntu/strigosuccess

#Add course CPs
for entry in /$STRIGO_CLASS_ID/configs/content_packs/*
do
  printf "\n\nInstalling Content Package: $entry\n" >> /home/ubuntu/strigosuccess
  id=$(cat "$entry" | jq -r '.id')
  ver=$(cat "$entry" | jq -r '.rev')
  printf "\n\nID:$entry and Version: $ver\n" >> /home/ubuntu/strigosuccess
  curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/content_packs"  -H 'Content-Type: application/json' -H 'X-Requested-By: PS_Packer' -d @"$entry" >> /home/ubuntu/strigosuccess
  printf "\n\nEnabling Content Package: $entry\n" >> /home/ubuntu/strigosuccess
  curl -u'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/content_packs/$id/$ver/installations" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"parameters":{},"comment":""}' >> /home/ubuntu/strigosuccess
done

#Update MaxMind DA with updated DB Path
echo "Updating MaxMind DA" >> /home/ubuntu/strigosuccess
id=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/system/lookup/adapters?page=1&per_page=50&sort=title&order=desc&query=Geo' | jq -r '.data_adapters[].id')
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/lookup/adapters/$id" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "{\"id\":\"$id\",\"title\":\"Geo IP - MaxMind™ Databases\",\"description\":\"Geo IP - MaxMind™ Databases\",\"name\":\"geo-ip-maxmind\",\"custom_error_ttl_enabled\":false,\"custom_error_ttl\":null,\"custom_error_ttl_unit\":null,\"config\":{\"type\":\"maxmind_geoip\",\"path\":\"/usr/share/graylog/data/config/GeoLite2-City.mmdb\",\"database_type\":\"MAXMIND_CITY\",\"check_interval\":1,\"check_interval_unit\":\"MINUTES\"}}" >> /home/ubuntu/strigosuccess

#Pausing Endpoint Firewalls Stream
printf "\n\nRetrieve Endpoint Firewalls Stream ID\n" >> /home/ubuntu/strigosuccess
gnefstreamid=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/streams/paginated?page=1&per_page=50&query=Endpoint%20Firewalls&sort=title&order=asc' | jq -r '.elements[].id')
printf "\n\nPausing Stream\n"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/streams/$gnefstreamid/pause" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' >> /home/ubuntu/strigosuccess

#Disable Whitelist
printf "\n\nDisable Whitelisting\n" >> /home/ubuntu/strigosuccess
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/urlwhitelist" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"entries":[],"disabled":true}' >> /home/ubuntu/strigosuccess

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

#Launch Docker to load changes in env file
echo "Running Docker Compose to update GL environment with new information" >> /home/ubuntu/strigosuccess
docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d
pwsh -c 'write-host "loaded PS!"'


#Cleanup
echo "Cleaning up" >> /home/ubuntu/strigosuccess
sed -i '/export apitoken=/d' /etc/profile
sed -i '/export authemail=/d' /etc/profile
rm -r /certs
rm -r /$STRIGO_CLASS_ID

echo "Complete!" >> /home/ubuntu/strigosuccess
