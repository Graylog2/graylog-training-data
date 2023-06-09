#!/bin/bash

# while true
# do
#     read -p "Hostname of Graylog server: " i
#     [ ! $i == "$publicdns" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $publicdns!)"
#     [[ $i == "$publicdns" ]] && break
# done

# while true
# do
#     read -p "Hostname of Opensearch server: " i
#     [ ! $i == "$dns_os" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $dns_os!)"
#     [[ $i == "$dns_os" ]] && break
# done


echo "=== Generating CSR's..."
sleep 2
echo "=== Submitting CSR's to CA for signing..."
sleep 4

mkdir $HOME/ssl
cd $HOME/ssl
sudo cp /etc/graylog/*.pem $HOME/ssl
sudo rm /etc/graylog/*.pem
sudo chown $LUSER.$LUSER -R $HOME/ssl
cp cert.pem graylog.pem
cp cert.pem opensearch.pem
cp privkey.pem graylog.key
cp privkey.pem opensearch.key
chmod 0600 ./*
rm cert.pem privkey.pem
echo "=== Certificates signature succeeded!"
echo "=== Your CA certificates, server certificates, and private keys have been uploaded to $HOME/ssl:"
echo "=== Graylog server cert     : $HOME/ssl/graylog.pem"
echo "=== Graylog server key      : $HOME/ssl/graylog.key"
echo "=== Opensearch server cert  : $HOME/ssl/opensearch.pem"
echo "=== Opensearch server key   : $HOME/ssl/opensearch.key"
echo "=== Intermediate CA cert    : $HOME/ssl/intermediate-ca.pem"
echo "=== Root CA cert            : $HOME/ssl/root-ca.pem"
echo "=== Full certificate chain  : $HOME/ssl/fullchain.pem"