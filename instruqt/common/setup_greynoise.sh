#!/bin/bash

# Setup Greynoise Lookup Table in Graylog

# Import env vars used throughout scripts runtime
source /etc/profile

# Create Greynoise Data Adapter:
printf "\n\nCreating Greynoise Data Adapter\n"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/lookup/adapters" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "{\"id\":null,\"title\":\"Greynoise Enterprise Full IP Lookup\",\"description\":\"Greynoise Enterprise Full IP Lookup\",\"name\":\"greynoise-enterprise-full-ip-lookup\",\"config\":{\"type\":\"GreyNoise Lookup [Enterprise]\",\"api_token\":{\"set_value\":\"$gn_api_key\"}}}"

# Create Greynoise Cache:
printf "\n\nCreating Greynoise Cache\n"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/lookup/caches" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"id":null,"title":"Greynoise Enterprise Full IP Lookup-cache","description":"Greynoise Enterprise Full IP Lookup-cache","name":"greynoise-enterprise-full-ip-lookup-cache","config":{"type":"guava_cache","max_size":1000,"expire_after_access":60,"expire_after_access_unit":"SECONDS","expire_after_write":0,"expire_after_write_unit":null}}'

# Create Greynoise Lookup Table:
printf "\n\nCreating Greynoise Lookup Table\n"
gncache=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/system/lookup/caches?page=1&per_page=50&sort=title&order=desc&query=greynoise' | jq -r '.caches[].id')
gnda=$(curl -u 'admin:yabba dabba doo' -XGET 'http://localhost:9000/api/system/lookup/adapters?page=1&per_page=50&sort=title&order=desc&query=Greynoise' | jq -r '.data_adapters[].id')
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/system/lookup/tables" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "{\"title\":\"Greynoise Enterprise Full IP Lookup Table\",\"description\":\"Greynoise Enterprise Full IP Lookup Table\",\"name\":\"greynoise-lookup\",\"default_single_value\":\"\",\"default_single_value_type\":\"NULL\",\"default_multi_value\":\"\",\"default_multi_value_type\":\"NULL\",\"data_adapter_id\":\"$gnda\",\"cache_id\":\"$gncache\"}"