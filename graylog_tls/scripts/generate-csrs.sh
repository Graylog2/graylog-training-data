#!/bin/bash

while true
do
    read -p "Hostname of Graylog server: " i
    [ ! $i == "$publicdns" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $publicdns!)"
    [[ $i == "$publicdns" ]] && break
done

while true
do
    read -p "Hostname of Opensearch server: " i
    [ ! $i == "$user-opensearch.logfather.org" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $user-opensearch.logfather.org!)"
    [[ $i == "$user-opensearch.logfather.org" ]] && break
done

while true
do
    read -p "Hostname of MongoDB server: " i
    [ ! $i == "$user-mongodb.logfather.org" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $user-mongodb.logfather.org!)"
    [[ $i == "$user-mongodb.logfather.org" ]] && break
done

echo "=== Generating CSR from provided info..."
sleep 1
echo "=== Submitting CSR to CA for signing..."
sleep 3

mkdir ~/ssl
sudo cp /home/admin/.class/certs/cert.pem /home/admin/.class/certs/privkey.pem /home/admin/.class/certs/fullchain.pem ~/ssl
sudo chown 1000.1000 -R ~/ssl
echo "=== Certificate signature succeeded!"
echo "=== Your certificate, private key, and full cert chain have been uploaded to the ~/ssl directory:"
echo "=== Server cert      : ~/ssl/cert.pem"
echo "=== Server key       : ~/ssl/privkey.pem"
echo "=== Cert trust chain : ~/ssl/fullchain.pem"
