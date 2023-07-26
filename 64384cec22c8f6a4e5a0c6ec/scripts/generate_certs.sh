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

# Clone certs from repo:
mkdir $HOME/ssl
cd $HOME/ssl
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs" >> $HOME/strigosuccess

echo "=== Submitting CSR's to CA for signing..."

# Import & decode cert files:
for i in ./*.enc
do
    openssl enc -in $i -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > /etc/graylog/"${i%.enc}"
    echo "Decoded ${i%.pem.enc}" >> $HOME/strigosuccess
done

sudo chown $LUSER.$LUSER -R $HOME/ssl
cp cert.pem graylog.pem
cp cert.pem opensearch.pem
cp privkey.pem graylog.key
cp privkey.pem opensearch.key
cp fullchain.pem servers_fullchain.pem
cp osadmin_cert.pem osadmin.pem
cp osadmin_privkey.pem osadmin.key
chmod 0400 ./*.key
rm cert.pem privkey.pem cacerts

printf "=== Certificates signed successfully!\n"
printf "=== Your server certificates, private keys, and certificate chain have been uploaded to $HOME/ssl:\n"
printf "=== Graylog server cert         :\e[0;31m $HOME/ssl/graylog.pem\e[0;37m\n"
printf "=== Graylog server key          :\e[0;31m $HOME/ssl/graylog.key\e[0;37m\n"
printf "=== Opensearch server cert      :\e[0;34m $HOME/ssl/opensearch.pem\e[0;37m\n"
printf "=== Opensearch server key       :\e[0;34m $HOME/ssl/opensearch.key\e[0;37m\n"
printf "=== Servers full cert chain     :\e[1;33m $HOME/ssl/servers_fullchain.pem\e[0;37m\n"
printf "=== Your Opensearch admin user certificate, key, and certificate chain have also been uploaded to $HOME/ssl:\n"
printf "=== Opensearch admin user cert  :\e[0;36m $HOME/ssl/osadmin.pem\e[0;37m\n"
printf "=== Opensearch admin user key   :\e[0;36m $HOME/ssl/osadmin.key\e[0;37m\n"
printf "=== Opensearch admin fullchain  :\e[1;36m $HOME/ssl/osadmin_fullchain.pem\e[0;37m\n"