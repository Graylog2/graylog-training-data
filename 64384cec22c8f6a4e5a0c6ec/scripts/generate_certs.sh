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

printf "\n\e[1;37m=== Certificates signed successfully!\e[0m\n"
printf "\n=== Your certificate files & private keys have been uploaded to: \e[1;93m/home/$LUSER/certs\e[0m\n\n"
printf "      \e[0;31mGraylog server cert ......... graylog.pem\e[0m\n"
printf "      \e[0;31mGraylog server key .......... graylog.key\e[0m\n"
printf "      \e[0;34mOpensearch server cert ...... opensearch.pem\e[0m\n"
printf "      \e[0;34mOpensearch server key ....... opensearch.key\e[0m\n"
printf "      \e[0;33mCertificate chain ........... servers_fullchain.pem\e[0m\n\n"
printf "      \e[0;36mOpensearch admin user cert .. osadmin.pem\e[0m\n"
printf "      \e[0;36mOpensearch admin user key ... osadmin.key\e[0m\n"
printf "      \e[0;33mOpensearch admin fullchain .. osadmin_fullchain.pem\e[0m\n"