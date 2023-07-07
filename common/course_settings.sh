#!/bin/bash
#load Vars from Strigo
source /etc/profile

#Update MaxMind DA with updated DB Path
echo "Updating MaxMind DA" >> /home/$LUSER/strigosuccess
id=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/system/lookup/adapters?page=1&per_page=50&sort=title&order=desc&query=Geo' | jq -r '.data_adapters[].id')
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/lookup/adapters/$id" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "{\"id\":\"$id\",\"title\":\"Geo IP - MaxMind™ Databases\",\"description\":\"Geo IP - MaxMind™ Databases\",\"name\":\"geo-ip-maxmind\",\"custom_error_ttl_enabled\":false,\"custom_error_ttl\":null,\"custom_error_ttl_unit\":null,\"config\":{\"type\":\"maxmind_geoip\",\"path\":\"/usr/share/graylog/data/config/GeoLite2-City.mmdb\",\"database_type\":\"MAXMIND_CITY\",\"check_interval\":1,\"check_interval_unit\":\"MINUTES\"}}" >> /home/$LUSER/strigosuccess

#Pausing Endpoint Firewalls Stream
printf "\n\nRetrieve Endpoint Firewalls Stream ID\n" >> /home/$LUSER/strigosuccess
gnefstreamid=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/streams/paginated?page=1&per_page=50&query=Endpoint%20Firewalls&sort=title&order=asc' | jq -r '.elements[].id')
printf "\n\nPausing Stream\n"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/streams/$gnefstreamid/pause" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' >> /home/$LUSER/strigosuccess

#Disable Whitelist
printf "\n\nDisable Whitelisting\n" >> /home/$LUSER/strigosuccess
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/urlwhitelist" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"entries":[],"disabled":true}' >> /home/$LUSER/strigosuccess
