#!/bin/bash

# Cleans up all repo files and sensitive env vars from during setup.
# MUST RUN LAST!
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -euxo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Cleanup
echo "Cleaning up" 
sed -i '/export apitoken=/d' /etc/profile
sed -i '/export authemail=/d' /etc/profile
sed -i '/license_enterprise=/d' /etc/profile
sed -i '/license_security=/d' /etc/profile
sed -i '/gn_api_key=/d' /etc/profile
sed -i '/authemail=/d' /etc/profile
sed -i '/apitoken=/d' /etc/profile

rm -r /certs
rm /root/.pwd
rm -r /$CLASS
rm -r /common

#Opensearch Replica Cleanup
curl -X PUT "http://127.0.0.1:9200/.opensearch-*/_settings" -H 'Content-Type: application/json' -d '{"index":{"number_of_replicas":0}}'
curl -X PUT "http://127.0.0.1:9200/.plugins-*/_settings" -H 'Content-Type: application/json' -d '{"index":{"number_of_replicas":0}}'

echo "Cleanup complete!" 