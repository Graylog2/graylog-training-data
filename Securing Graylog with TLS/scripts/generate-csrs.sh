#!/bin/bash

while true
do
    read -p "Hostname of Graylog server: " i
    [ ! $i == "$publicdns" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $publicdns!)"
    [[ $i == "$publicdns" ]] && break
done

while true
do
    read -p "Hostname of MongoDB server: " i
    [ ! $i == "$publicdns_mg" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $publicdns_mg!)"
    [[ $i == "$publicdns_mg" ]] && break
done

while true
do
    read -p "Hostname of Opensearch server: " i
    [ ! $i == "$publicdns_os" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $publicdns_os!)"
    [[ $i == "$publicdns_os" ]] && break
done


echo "=== Generating CSR's from provided info..."
sleep 2
echo "=== Submitting CSR's to CA for signing..."
sleep 4

mkdir ~/ssl
cd ~/ssl
sudo cp /home/admin/.class/certs/* .
sudo chown 1000.1000 -R ~/ssl
cp cert.pem graylog.pem
cp cert.pem mongodb.pem
cp cert.pem opensearch.pem
cp privkey.pem graylog.key
cp privkey.pem mongodb.key
cp privkey.pem opensearch.key
rm cert.pem privkey.pem fullchain.pem
echo "=== Certificates signature succeeded!"
echo "=== Your CA certificates, server certificates, and private keys have been uploaded to the $HOME/ssl directory:"
echo "=== Graylog server cert     : $HOME/ssl/graylog.pem"
echo "=== Graylog server key      : $HOME/ssl/graylog.key"
echo "=== MongoDB server cert     : $HOME/ssl/mongodb.pem"
echo "=== MongoDB server key      : $HOME/ssl/mongodb.key"
echo "=== MongoDB server cert     : $HOME/ssl/opensearch.pem"
echo "=== MongoDB server key      : $HOME/ssl/opensearch.key"
echo "=== Intermediate CA cert    : $HOME/ssl/intermediate-ca.pem"
echo "=== Root CA cert            : $HOME/ssl/root-ca.pem"