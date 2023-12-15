#!/bin/bash

# Setup Maxmind GeoLite2 GeoIP Databases (Docker and non-Docker envs)

# Import env vars used throughout scripts runtime
source /etc/profile

# Run different commands depending on if Docker env or not:
echo "Importing Maxmind GeoIP Databases"
if [[ $NEEDS_DOCKER ]]; then
    glc=$(sudo docker ps | grep graylog-enterprise | awk '{print $1}')
    sudo docker cp /common/geodb/GeoLite2-ASN.mmdb $glc:/usr/share/graylog/data/config/GeoLite2-ASN.mmdb
    sudo sudo docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/GeoLite2-ASN.mmdb
    sudo docker cp /common/geodb/GeoLite2-City.mmdb $glc:/usr/share/graylog/data/config/GeoLite2-City.mmdb
    sudo sudo docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/GeoLite2-City.mmdb
    sudo docker cp /common/geodb/GeoLite2-Country.mmdb $glc:/usr/share/graylog/data/config/GeoLite2-Country.mmdb
    sudo sudo docker exec -u root -i $glc chown graylog.graylog /usr/share/graylog/data/config/GeoLite2-Country.mmdb
else
    mv /common/geodb/*.mmdb /usr/share/graylog/data/config
    chown graylog.graylog /usr/share/graylog/data/config/*.mmdb
    chmod 0400 /usr/share/graylog/data/config/*.mmdb
fi

# Update MaxMind DA with new DB Path
echo "Updating MaxMind DA" 
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/cluster_config/org.graylog.plugins.map.config.GeoIpResolverConfig" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"enabled":true,"enforce_graylog_schema":true,"db_vendor_type":"MAXMIND","city_db_path":"/usr/share/graylog/data/config/GeoLite2-City.mmdb","asn_db_path":"/usr/share/graylog/data/config/GeoLite2-ASN.mmdb","refresh_interval_unit":"MINUTES","refresh_interval":10,"use_s3":false}'