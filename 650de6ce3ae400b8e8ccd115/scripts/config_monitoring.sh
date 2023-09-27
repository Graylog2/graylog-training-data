#!/bin/bash
#load Vars from Strigo
source /etc/profile

#Delete existing Docker config
echo "Delete existing docker compose" >> /home/$LUSER/strigosuccess
rm -r /etc/graylog/docker-compose-glservices.yml

#Create folder
mkdir /etc/graylog/grafana

#Copy files to correct locations
echo "Copy required files" >> /home/$LUSER/strigosuccess
mv "/$STRIGO_CLASS_ID/configs/prometheus/process_exporter.yml" /etc/graylog/
mv "/$STRIGO_CLASS_ID/configs/prometheus/prometheus-exporter-mapping-custom.yml" /etc/graylog/
mv "/$STRIGO_CLASS_ID/configs/prometheus/prometheus.yml" /etc/graylog/
mv "/$STRIGO_CLASS_ID/configs/docker/mon-compose.yml" /etc/graylog/docker-compose-glservices.yml #Reuse name to prevent need to update other scripts
mv "/$STRIGO_CLASS_ID/configs/grafana/Elasticsearch.json" /etc/graylog/grafana/
mv "/$STRIGO_CLASS_ID/configs/grafana/Graylog-Server.json" /etc/graylog/grafana/

#Rebuild Docker
echo "Rerun compose with new services" >> /home/$LUSER/strigosuccess
docker compose -f /etc/graylog/docker-compose-glservices.yml --env-file /etc/graylog/strigo-graylog-training-changes.env up -d

#Wait for Grafana
while ! curl -s -u 'admin:admin' http://localhost:3000; do
	printf "\n\nWaiting for Grafana to come online to add content\n" >> /home/$LUSER/strigosuccess
    sleep 5
done

#Add promo to Grafana
echo "Add prom to grafana" >> /home/$LUSER/strigosuccess
GDS=$(curl -X POST -H "Content-Type: application/json" -d '{"name":"Prometheus","type":"prometheus","url":"http://prometheus:9090","access":"proxy","basicAuth":false}' http://admin:admin@localhost:3000/api/datasources)
GUID=$(echo $GDS | jq -r '.datasource.uid')
echo "datasource UID: $GUID" >> /home/$LUSER/strigosuccess

#Update DB File with new datasource ID
echo "Update dashboards with correct datasource" >> /home/$LUSER/strigosuccess
sed -i "s/f934cd4d-5189-433a-a001-3f2526c0ccb0/$GUID/g" /etc/graylog/grafana/Graylog-Server.json 
sed -i "s/f934cd4d-5189-433a-a001-3f2526c0ccb0/$GUID/g" /etc/graylog/grafana/Elasticsearch.json     

#Add DB to Grafana
echo "Add dashboards to grafana" >> /home/$LUSER/strigosuccess
curl -X POST -H "Content-Type: application/json" -d @/etc/graylog/grafana/Graylog-Server.json http://admin:admin@localhost:3000/api/dashboards/import
curl -X POST -H "Content-Type: application/json" -d @/etc/graylog/grafana/Elasticsearch.json http://admin:admin@localhost:3000/api/dashboards/import

#Install Nginx
echo "Adding NGINX to slap headers in for grafana" >> /home/$LUSER/strigosuccess
apt install nginx -y
rm -r /etc/nginx/sites-enabled/default
echo -e "server {
    listen 80;
    listen [::]:80;

    location / {
        proxy_set_header Host \$http_host;
        proxy_pass           http://localhost:3000/;
    
    if (\$request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        #
        # Custom headers and headers various browsers *should* be OK with but aren't
        #
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
        #
        # Tell client that this pre-flight info is valid for 20 days
        #
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
     }
     if (\$request_method = 'POST') {
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
     }
     if (\$request_method = 'GET') {
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
     }
   }
}
" > /etc/nginx/sites-enabled/grafana.conf
systemctl restart nginx
