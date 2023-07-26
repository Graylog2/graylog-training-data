#!/bin/bash

echo "=== Generating CSR's..."
sleep 2
echo "=== Submitting CSR's to CA for signing..."
sleep 4

mkdir /home/$LUSER/certs
cd /.ssl
cp cert.pem /home/$LUSER/certs/graylog.pem
cp cert.pem /home/$LUSER/certs/opensearch.pem
cp privkey.pem /home/$LUSER/certs/graylog.key
cp privkey.pem /home/$LUSER/certs/opensearch.key
cp fullchain.pem /home/$LUSER/certs/servers_fullchain.pem
cp osadmin_cert.pem /home/$LUSER/certs/osadmin.pem
cp osadmin_privkey.pem /home/$LUSER/certs/osadmin.key
chmod 0400 /home/$LUSER/certs/*.key
sudo rm -rf /.ssl

printf "=== Certificates signed successfully!\n"
printf "=== Your server certificates, private keys, and certificate chain have been uploaded to /home/$LUSER/certs:\n"
printf "=== Graylog server cert         :\e[0;31m /home/$LUSER/certs/graylog.pem\e[0;37m\n"
printf "=== Graylog server key          :\e[0;31m /home/$LUSER/certs/graylog.key\e[0;37m\n"
printf "=== Opensearch server cert      :\e[0;34m /home/$LUSER/certs/opensearch.pem\e[0;37m\n"
printf "=== Opensearch server key       :\e[0;34m /home/$LUSER/certs/opensearch.key\e[0;37m\n"
printf "=== Servers full cert chain     :\e[1;33m /home/$LUSER/certs/servers_fullchain.pem\e[0;37m\n"
printf "=== Your Opensearch admin user certificate, key, and certificate chain have also been uploaded to /home/$LUSER/certs:\n"
printf "=== Opensearch admin user cert  :\e[0;36m /home/$LUSER/certs/osadmin.pem\e[0;37m\n"
printf "=== Opensearch admin user key   :\e[0;36m /home/$LUSER/certs/osadmin.key\e[0;37m\n"
printf "=== Opensearch admin fullchain  :\e[1;36m /home/$LUSER/certs/osadmin_fullchain.pem\e[0m\n"