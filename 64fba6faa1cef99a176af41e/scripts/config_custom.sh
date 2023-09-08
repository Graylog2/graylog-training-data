#!/bin/bash
# Hardening Graylog Class custom script:

# Create course motd banner:
cat <<EOF >> /home/$LUSER/.bashrc
printf "\e[37m ██████╗ ██████╗  █████╗ ██╗   ██╗\e[31m██╗      ██████╗  ██████╗ \n";
printf "\e[37m██╔════╝ ██╔══██╗██╔══██╗╚██╗ ██╔╝\e[31m██║     ██╔═══██╗██╔════╝ \n";
printf "\e[37m██║  ███╗██████╔╝███████║ ╚████╔╝ \e[31m██║     ██║   ██║██║  ███╗\n";
printf "\e[37m██║   ██║██╔══██╗██╔══██║  ╚██╔╝  \e[31m██║     ██║   ██║██║   ██║\n";
printf "\e[37m╚██████╔╝██║  ██║██║  ██║   ██║   \e[31m███████╗╚██████╔╝╚██████╔╝\n";
printf "\e[37m ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   \e[31m╚══════╝ ╚═════╝  ╚═════╝ \n";
printf "                                                            \n";
printf "\e[39m Hi ${STRIGO_USER_NAME},\n Welcome to ${STRIGO_CLASS_NAME}\n\n";
printf "\e[39m Your Graylog server can be reached at the following URL:\n\n"
printf "\t\e[93mhttp://$dns.logfather.org:9000/\n\n\e[39m";

PATH=$PATH:/usr/share/graylog-server/jvm/bin
EOF


### Special cert setup section bc this class can't use the common certs.sh script:

# Import certs from repo & decode:
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs" /.ssl
cd /.ssl
for i in ./*.enc
do
    openssl enc -in $i -aes-256-cbc -pbkdf2 -d -pass file:/.pwd > "${i%.enc}"
    echo "Decoded ${i%.pem.enc}"
done

# Add logfather.org cert chain to host CA trust store to avoid having to use -k flag in curl commands:
openssl x509 -inform PEM -in fullchain.pem -out /usr/local/share/ca-certificates/fullchain.crt
update-ca-certificates

# Delete demo files:
rm /etc/opensearch/*.pem

# Delete unneeded files:
rm /.ssl/*.enc /.ssl/cacerts /.ssl/root-ca.pem /.ssl/intermediate-ca.pem



### Misc course-specific stuff:

# Create Inputs:
curl -k -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.gelf.http.GELFHttpInput","configuration":{"bind_address":"0.0.0.0","port":12201,"recv_buffer_size":1048576,"number_worker_threads":1,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"enable_bulk_receiving":false,"enable_cors":true,"max_http_chunk_size":65536,"idle_writer_timeout":60,"override_source":null,"charset_name":"UTF-8","decompress_size_limit":8388608},"title":"GELF HTTP","global":true}'

# Import CSR generator script:
cp "/$STRIGO_CLASS_ID/scripts/generate_certs.sh" /home/$LUSER/generate_certs.sh
chmod +x /home/$LUSER/generate_certs.sh