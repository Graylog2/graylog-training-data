#!/bin/bash

### Hardening Graylog with TLS
### Course-specific Setup Script

# Import env vars used throughout scripts runtime
source /etc/profile

# Log start
printf "=== $(basename $0) === Starting...\n"

# Import certs:
#echo "Grabbing Certs" 
#git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/certs" /certs
echo "Processing Certs"

# Import & decode cert files:
for i in /certs/*.enc
do
    openssl enc -in $i -aes-256-cbc -pbkdf2 -d -pass file:/root/.pwd > "${i%.enc}"
    echo "Decoded ${i%.pem.enc}"
done

# Make temp obfuscated folder to store decoded certs for use in generate_certs.sh later
# and to avoid deletion by cleanup.sh:
mkdir /.ssl

# Move decoded certs to temp folder:
mv /certs/*.pem /.ssl

# Add logfather.org cert chain to host CA trust store
# to avoid having to use -k flag in curl commands:
openssl x509 -inform PEM -in /.ssl/fullchain.pem -out /usr/local/share/ca-certificates/fullchain.crt
update-ca-certificates

# Create Graylog Inputs:
curl -k -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.gelf.http.GELFHttpInput","configuration":{"bind_address":"0.0.0.0","port":12201,"recv_buffer_size":1048576,"number_worker_threads":1,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"enable_bulk_receiving":false,"enable_cors":true,"max_http_chunk_size":65536,"idle_writer_timeout":60,"override_source":null,"charset_name":"UTF-8","decompress_size_limit":8388608},"title":"GELF HTTP","global":true}'

# Delete demo files:
rm /etc/opensearch/*.pem

# Import CSR generator script:
cp "/$CLASS/scripts/generate_certs.sh" /root/generate_certs.sh
chmod +x /root/generate_certs.sh

# Add student CNAME to /etc/cloud/templates/hosts.debian.tmpl to prevent "Unable to call proxied resource" errors in server.log
# as well as allow apps to resolve this hostname after instance pause & resume:
echo "127.0.0.1 $dns.instruqt.io" >> /etc/cloud/templates/hosts.debian.tmpl