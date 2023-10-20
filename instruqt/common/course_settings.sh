#!/bin/bash
#load Vars from Strigo
source /etc/profile

#Update MaxMind DA with updated DB Path
echo "Updating MaxMind DA" 
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/cluster_config/org.graylog.plugins.map.config.GeoIpResolverConfig" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"enabled":true,"enforce_graylog_schema":true,"db_vendor_type":"MAXMIND","city_db_path":"/usr/share/graylog/data/config/GeoLite2-City.mmdb","asn_db_path":"/usr/share/graylog/data/config/GeoLite2-ASN.mmdb","refresh_interval_unit":"MINUTES","refresh_interval":10,"use_s3":false}' 

#Disable Whitelist
printf "\n\nDisable Whitelisting\n" 
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/urlwhitelist" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"entries":[],"disabled":true}' 

if [[ "$CLASS" == "threat_hunting" ]]; then
    #Threat Hunter
    #Pausing Endpoint Firewalls Stream
    printf "\n\nRetrieve Endpoint Firewalls Stream ID\n" 
    gnefstreamid=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/streams/paginated?page=1&per_page=50&query=Endpoint%20Firewalls&sort=title&order=asc' | jq -r '.elements[].id')
    printf "\n\nPausing Stream\n"
    curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/streams/$gnefstreamid/pause" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' 
fi