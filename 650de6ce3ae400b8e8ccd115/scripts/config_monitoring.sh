#!/bin/bash
#load Vars from Strigo
source /etc/profile

#Delete existing Docker config
echo "Delete existing docker compose" >> /home/$LUSER/strigosuccess
rm -r /etc/graylog/docker-compose-glservices.yml

#Copy files to correct locations
echo "Copy required files" >> /home/$LUSER/strigosuccess
mv "/$STRIGO_CLASS_ID/configs/prometheus/process_exporter.yml" /etc/graylog/
mv "/$STRIGO_CLASS_ID/configs/prometheus/prometheus-exporter-mapping-custom.yml" /etc/graylog/
mv "/$STRIGO_CLASS_ID/configs/prometheus/prometheus.yml" /etc/graylog/
mv "/$STRIGO_CLASS_ID/configs/docker/mon-compose.yml" /etc/graylog/docker-compose-glservices.yml #Reuse name to prevent need to update other scripts

