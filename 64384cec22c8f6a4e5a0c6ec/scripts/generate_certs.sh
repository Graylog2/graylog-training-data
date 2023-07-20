#!/bin/bash

# while true
# do
#     read -p "Hostname of Graylog server: " i
#     [ ! $i == "$publicdns" ] && echo "Please make sure this name matches the full domain name of your lab instance! (Hint: it's $publicdns!)"
#     [[ $i == "$publicdns" ]] && break
# done
# 
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
cp /certs/*.pem .
sudo rm -rf /certs
sudo chown admin.admin -R $HOME/ssl
cp cert.pem graylog.pem
cp cert.pem opensearch.pem
cp privkey.pem graylog.key
cp privkey.pem opensearch.key
chmod 0400 ./*.key
rm cert.pem privkey.pem

printf "=== Certificates signature succeeded!\n"
printf "=== Your CA certificates, server certificates, and private keys have been uploaded to $HOME/ssl:\n"
printf "=== Graylog server cert     :\e[0;32m $HOME/ssl/graylog.pem\e[0;37m\n"
printf "=== Graylog server key      :\e[1;32m $HOME/ssl/graylog.key\e[0;37m\n"
printf "=== Opensearch server cert  :\e[0;33m $HOME/ssl/opensearch.pem\e[0;37m\n"
printf "=== Opensearch server key   :\e[1;33m $HOME/ssl/opensearch.key\e[0;37m\n"
printf "=== Intermediate CA cert    :\e[0;36m $HOME/ssl/intermediate-ca.pem\e[0;37m\n"
printf "=== Root CA cert            :\e[1;36m $HOME/ssl/root-ca.pem\e[0;37m\n"