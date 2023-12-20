#!/bin/bash

# Setup Maxmind GeoLite2 GeoIP Databases (Docker and non-Docker envs).
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile


# Run different commands depending on if Docker env or not:
echo "Importing Maxmind GeoIP Databases"
if [[ $NEEDS_DOCKER ]]; then
    glc=$(docker ps | grep graylog-enterprise | awk '{print $1}')
    docker cp /common/geodb/GeoLite2-ASN.mmdb $glc:/usr/share/graylog/data/config/GeoLite2-ASN.mmdb
    docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/GeoLite2-ASN.mmdb
    docker cp /common/geodb/GeoLite2-City.mmdb $glc:/usr/share/graylog/data/config/GeoLite2-City.mmdb
    docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/GeoLite2-City.mmdb
    docker cp /common/geodb/GeoLite2-Country.mmdb $glc:/usr/share/graylog/data/config/GeoLite2-Country.mmdb
    docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/GeoLite2-Country.mmdb
else
    mv /common/geodb/*.mmdb /usr/share/graylog/data/config
    chown graylog.graylog /usr/share/graylog/data/config/*.mmdb
    chmod 0400 /usr/share/graylog/data/config/*.mmdb
fi

# Update MaxMind DA with new DB Path
echo "Updating MaxMind DA" 
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/cluster_config/org.graylog.plugins.map.config.GeoIpResolverConfig" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"enabled":true,"enforce_graylog_schema":true,"db_vendor_type":"MAXMIND","city_db_path":"/usr/share/graylog/data/config/GeoLite2-City.mmdb","asn_db_path":"/usr/share/graylog/data/config/GeoLite2-ASN.mmdb","refresh_interval_unit":"MINUTES","refresh_interval":10,"use_s3":false}'