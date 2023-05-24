#!/bin/bash

# Set $dns2 to the common root domain name: "[username]-lab"
dns2=${dns%-*}

while true
do
    read -p "Hostname of Graylog server: " i
    [ ! $i == "$dns.logfather.org" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $dns.logfather.org!)"
    [[ $i == "$dns.logfather.org" ]] && break
done

while true
do
    read -p "Hostname of Opensearch server: " i
    [ ! $i == "$dns2-opensearch.logfather.org" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $dns2-opensearch.logfather.org!)"
    [[ $i == "$dns2-opensearch.logfather.org" ]] && break
done


echo "=== Generating CSR from provided info..."
sleep 1
echo "=== Submitting CSR to CA for signing..."
sleep 3

mkdir ~/ssl
sudo cp /etc/graylog/cert.pem /etc/graylog/privkey.pem /etc/graylog/fullchain.pem ~/ssl
sudo chown $USER.$USER -R ~/ssl
echo "=== Certificate signature succeeded!"
echo "=== Your certificate, private key, and full cert chain have been uploaded to the ~/ssl directory:"
echo "=== Server cert      : ~/ssl/cert.pem"
echo "=== Server key       : ~/ssl/privkey.pem"
echo "=== Cert trust chain : ~/ssl/fullchain.pem"
