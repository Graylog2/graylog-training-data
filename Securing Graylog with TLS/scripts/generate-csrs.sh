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
    [ ! $i == "$dns_mg" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $dns_mg!)"
    [[ $i == "$dns_mg" ]] && break
done

while true
do
    read -p "Hostname of Opensearch server: " i
    [ ! $i == "$dns_os" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $dns_os!)"
    [[ $i == "$dns_os" ]] && break
done


echo "=== Generating CSR's from provided info..."
sleep 2
echo "=== Submitting CSR's to CA for signing..."
sleep 4

mkdir $HOME/ssl
cd $HOME/ssl
sudo cp /certs/* .
sudo rm -rf /certs
sudo chown 1000.1000 -R .
cp cert.pem.enc graylog.pem
cp cert.pem.enc mongodb.pem
cp cert.pem.enc opensearch.pem
cp privkey.pem.enc graylog.key
cp privkey.pem.enc mongodb.key
cp privkey.pem.enc opensearch.key
rm cert.pem.enc privkey.pem.enc fullchain.pem.enc
echo "=== Certificates signature succeeded!"
echo "=== Your CA certificates, server certificates, and private keys have been uploaded to $HOME/ssl:"
echo "=== Graylog server cert     : $HOME/ssl/graylog.pem"
echo "=== Graylog server key      : $HOME/ssl/graylog.key"
echo "=== MongoDB server cert     : $HOME/ssl/mongodb.pem"
echo "=== MongoDB server key      : $HOME/ssl/mongodb.key"
echo "=== MongoDB server cert     : $HOME/ssl/opensearch.pem"
echo "=== MongoDB server key      : $HOME/ssl/opensearch.key"
echo "=== Intermediate CA cert    : $HOME/ssl/intermediate-ca.pem"
echo "=== Root CA cert            : $HOME/ssl/root-ca.pem"