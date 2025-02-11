#!/bin/bash

echo "=== Generating CSR's..."
sleep 2
echo "=== Submitting CSR's to CA for signing..."
sleep 4

# If certs dir does not exist, make it:
[[ ! -d /root/certs ]] && mkdir /root/certs
cd /.ssl
cp cert.pem /root/certs/graylog.pem
cp privkey.pem /root/certs/graylog.key
cp fullchain.pem /root/certs/fullchain.pem
chmod 0400 /root/certs/*.key

printf "\n\e[1;37m=== Certificates signed successfully!\e[0m\n"
printf "\n=== Your certificate files & private keys have been uploaded to: \e[1;93m/root/certs\e[0m\n\n"
printf "      \e[0;31mGraylog server cert ......... graylog.pem\e[0m\n"
printf "      \e[0;31mGraylog server key .......... graylog.key\e[0m\n"
printf "      \e[0;33mCertificate chain ........... fullchain.pem\e[0m\n\n"