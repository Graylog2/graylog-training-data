#!/bin/bash

# Import env vars used throughout scripts runtime
source /etc/profile

# Setup OliveTin:
# /common/setup_olivetin.sh

# Setup Greynoise:
# /common/setup_greynoise.sh

# Setup Maxmind GeoIP databases:
/common/setup_geoip.sh

#LogData
# sudo mv /$CLASS/log_data/* /root/powershell/Data
# sudo chown -R root.root /root
# mkdir /home/ubuntu/pipeline_rules
# sudo mv /$CLASS/pipeline_rules/* /home/ubuntu/pipeline_rules

#Creating Indices
printf "\n\n$(date)-Create General Desktop Events Index\n"
curl -u 'admin:yabba dabba doo' -XPOST 'http://localhost:9000/api/system/indices/index_sets' -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"title":"General Desktop Events","description":"General Desktop Events","index_prefix":"general-desktop","writable":true,"can_be_default":true,"shards":2,"replicas":0,"retention_strategy_class":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategy","retention_strategy":{"max_number_of_indices":3,"type":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategyConfig"},"index_analyzer":"standard","index_optimization_max_num_segments":1,"index_optimization_disabled":false,"field_type_refresh_interval":5000,"rotation_strategy_class":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategy","rotation_strategy":{"max_docs_per_index":20000,"type":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategyConfig"},"creation_date":"2022-08-17T21:06:47.393Z"}'
printf "\n\n$(date)-Create Training Index\n"
curl -u 'admin:yabba dabba doo' -XPOST 'http://localhost:9000/api/system/indices/index_sets' -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"title":"Training","description":"Training","index_prefix":"train","writable":true,"can_be_default":true,"shards":2,"replicas":0,"retention_strategy_class":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategy","retention_strategy":{"max_number_of_indices":3,"type":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategyConfig"},"index_analyzer":"standard","index_optimization_max_num_segments":1,"index_optimization_disabled":false,"field_type_refresh_interval":5000,"rotation_strategy_class":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategy","rotation_strategy":{"max_docs_per_index":20000,"type":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategyConfig"},"creation_date":"2022-08-17T21:06:47.393Z"}'

#Cert Injection
/common/certs.sh

#Course Settings
/common/course_settings.sh 

#Add course CPs
# /common/cp_inst.sh 

#OT Theme
/common/ot_gl_theme.sh 

#Update GL Docker Environment
## After this point everything will be HTTPS
/common/docker_graylog_https.sh

#Illuminate Install - moved to POST docker update. Illuminate doesn't seem to fetch first time graylog runs
/common/inst_illuminate.sh 

#Temp switch to latest GL Version
lgl=$(curl -L --fail "https://hub.docker.com/v2/repositories/graylog/graylog/tags/?page_size=1000" | jq '.results | .[] | .name' -r | sed 's/latest//' | sort --version-sort | tail -n 1)
dcv=$(sed -n 's/image: "graylog\/graylog-enterprise://p' docker-compose-glservices.yml | tr -d '"' | tr -d " ")
sed -i "s+enterprise\:$dcv+enterprise\:$lgl+g" docker-compose-glservices.yml
docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env up -d


echo "Complete!" 