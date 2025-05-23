#!/bin/bash
#load Vars from Strigo
source /etc/profile

# Install dependency jq:
apt install jq -y 

echo "Sleeping for random time up to 30 seconds to prevent DNS records from being over-written in cases of multiple labs starting at once" >> /home/$LUSER/strigosuccess
sleep $(( ( RANDOM % 30 )  + 1 ))

echo "The present working directory is $(pwd)" >> /home/$LUSER/strigosuccess
echo "Running DNS Registration Steps" >> /home/$LUSER/strigosuccess
dnscount=0
DNSMatch=false
#Check for Existing DNS Record
echo "Checking for existing record, $dns.logfather.org, result:" >> /home/$LUSER/strigosuccess
DNSCheck=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records?type=CNAME&name=$dns.logfather.org&match=all" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" | jq -r '.result[]')
echo $DNSCheck >> /home/$LUSER/strigosuccess
if [ ! -z "$DNSCheck" ]; then
    #Check it's CName to see if it matches existing DNS Record
    echo "Checking if CNAME is the same, result:" >> /home/$LUSER/strigosuccess
    CName=$(echo $DNSCheck | jq -r '.content')
    echo "$CName vs $LAB" >> /home/$LUSER/strigosuccess
    if [[ ! "$CName" == "$LAB" ]]; then
        #No Match - new DNS record but also need to check for more numbers
        #Loop through numbers and check for existing  DNS Records
        echo "Not a match, looping to find unused DNS record" >> /home/$LUSER/strigosuccess
        until [[ -z "$DNSCheck" ]];
        do
            #Add one to dnscount and check if that record exists. This will loop until null OR a matched CName is found in cases of paused labs THIS causes issues so lets fix it!
            ((dnscount++))
            DNSCheck=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records?type=CNAME&name=$dns$dnscount.logfather.org&match=all" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" | jq -r '.result[]')
            CName=$(echo $DNSCheck | jq -r '.content')
            echo "Comparing new DNS record's CNAME (if there is one), result" >> /home/$LUSER/strigosuccess
            echo $CName >> /home/$LUSER/strigosuccess
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
    echo "Creating DNS Record for: $dns" >> /home/$LUSER/strigosuccess
    cdata="{\"type\":\"CNAME\",\"name\":\"$dns\",\"content\":\"$LAB\",\"ttl\":3600,\"priority\":10,\"proxied\":false}"
    createcname=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" --data $cdata)
    result=$(echo $createcname | jq '.success')
    echo "Result: $result" >> /home/$LUSER/strigosuccess
fi
echo $dns >> /home/$LUSER/DNSSuccess
echo "Registered DNS record: $dns" >> /home/$LUSER/strigosuccess
sed -i '/export dns=/d' /etc/profile
echo "export dns=$dns" >> /etc/profile

echo "DNS setup complete!" >> /home/$LUSER/strigosuccess