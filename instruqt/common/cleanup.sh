#!/bin/bash
#load Vars from Strigo
source /etc/profile

#Cleanup
echo "Cleaning up" 
sed -i '/export apitoken=/d' /etc/profile
sed -i '/export authemail=/d' /etc/profile
rm -r /certs
rm /.pwd
rm -r /$CLASS
rm -r /common

#Opensearch Replica Cleanup
curl -X PUT "http://127.0.0.1:9200/.opensearch-*/_settings" -H 'Content-Type: application/json' -d '{"index":{"number_of_replicas":0}}'
curl -X PUT "http://127.0.0.1:9200/.plugins-*/_settings" -H 'Content-Type: application/json' -d '{"index":{"number_of_replicas":0}}'

echo "Cleanup complete!" 