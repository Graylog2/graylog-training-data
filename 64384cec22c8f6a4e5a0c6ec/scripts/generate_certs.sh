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

mkdir $HOME/certs
cd $HOME/.ssl
cp cert.pem ../certs/graylog.pem
cp cert.pem ../certs/opensearch.pem
cp privkey.pem ../certs/graylog.key
cp privkey.pem ../certs/opensearch.key
cp fullchain.pem ../certs/servers_fullchain.pem
cp osadmin_cert.pem ../certs/osadmin.pem
cp osadmin_privkey.pem ../certs/osadmin.key
chmod 0400 ../certs/*.key
rm -rf $HOME/.ssl

printf "=== Certificates signed successfully!\n"
printf "=== Your server certificates, private keys, and certificate chain have been uploaded to $HOME/certs:\n"
printf "=== Graylog server cert         :\e[0;31m $HOME/certs/graylog.pem\e[0;37m\n"
printf "=== Graylog server key          :\e[0;31m $HOME/certs/graylog.key\e[0;37m\n"
printf "=== Opensearch server cert      :\e[0;34m $HOME/certs/opensearch.pem\e[0;37m\n"
printf "=== Opensearch server key       :\e[0;34m $HOME/certs/opensearch.key\e[0;37m\n"
printf "=== Servers full cert chain     :\e[1;33m $HOME/certs/servers_fullchain.pem\e[0;37m\n"
printf "=== Your Opensearch admin user certificate, key, and certificate chain have also been uploaded to $HOME/certs:\n"
printf "=== Opensearch admin user cert  :\e[0;36m $HOME/certs/osadmin.pem\e[0;37m\n"
printf "=== Opensearch admin user key   :\e[0;36m $HOME/certs/osadmin.key\e[0;37m\n"
printf "=== Opensearch admin fullchain  :\e[1;36m $HOME/certs/osadmin_fullchain.pem\e[0m\n"