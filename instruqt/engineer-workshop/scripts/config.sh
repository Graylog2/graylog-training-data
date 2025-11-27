#!/bin/bash

# Import env vars used throughout scripts runtime
source /etc/profile

# Setup OliveTin:
/common/setup_olivetin.sh

# Setup Greynoise:
/common/setup_greynoise.sh

# Setup Maxmind GeoIP databases:
/common/setup_geoip.sh

#LogData
sudo chown -R root.root /$CLASS/log_data/
sudo mkdir -p /etc/graylog/log_data
sudo mv /$CLASS/log_data/* /etc/graylog/log_data/
#sudo chown -R root.root /root

#sudo mv /root/powershell/Data/firewall.log /etc/graylog/log_data/
#sudo mv /root/powershell/Data/kvp.log /etc/graylog/log_data/
#sudo mv /root/powershell/Data/bd-day3.log /etc/graylog/log_data/

#Creating Indices
#printf "\n\n$(date)-Create General Desktop Events Index\n"
#curl -u 'admin:yabba dabba doo' -XPOST 'http://localhost:9000/api/system/indices/index_sets' -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"title":"General Desktop Events","description":"General Desktop Events","index_prefix":"general-desktop","writable":true,"can_be_default":true,"shards":2,"replicas":0,"retention_strategy_class":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategy","retention_strategy":{"max_number_of_indices":3,"type":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategyConfig"},"index_analyzer":"standard","index_optimization_max_num_segments":1,"index_optimization_disabled":false,"field_type_refresh_interval":5000,"rotation_strategy_class":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategy","rotation_strategy":{"max_docs_per_index":20000,"type":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategyConfig"},"creation_date":"2022-08-17T21:06:47.393Z"}'
#printf "\n\n$(date)-Create Training Index\n"
#curl -u 'admin:yabba dabba doo' -XPOST 'http://localhost:9000/api/system/indices/index_sets' -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"title":"Training","description":"Training","index_prefix":"train","writable":true,"can_be_default":true,"shards":2,"replicas":0,"retention_strategy_class":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategy","retention_strategy":{"max_number_of_indices":3,"type":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategyConfig"},"index_analyzer":"standard","index_optimization_max_num_segments":1,"index_optimization_disabled":false,"field_type_refresh_interval":5000,"rotation_strategy_class":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategy","rotation_strategy":{"max_docs_per_index":20000,"type":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategyConfig"},"creation_date":"2022-08-17T21:06:47.393Z"}'

#Cert Injection
/common/certs.sh

#Course Settings
/common/course_settings.sh 

#Add course CPs
/common/cp_inst.sh 

#OT Theme
/common/ot_gl_theme.sh 

#Update GL Docker Environment
## After this point everything will be HTTPS
/common/docker_graylog_https.sh

#Illuminate Install - moved to POST docker update. Illuminate doesn't seem to fetch first time graylog runs
/common/inst_illuminate.sh 

# Create GELF input:
curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.gelf.tcp.GELFTCPInput","configuration":{"bind_address":"0.0.0.0","port":12201,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":true,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8","decompress_size_limit":8388608},"title":"GELF TCP","global":true,"node":"193f0219-bd7d-4635-8eec-6ce7ed9daca9"}'
#curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/system/inputs" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"type":"org.graylog2.inputs.syslog.tcp.SyslogTCPInput","configuration":{"bind_address":"0.0.0.0","port":514,"recv_buffer_size":1048576,"number_worker_threads":2,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"charset_name":"UTF-8","force_rdns":false,"allow_override_date":true,"store_full_message":false,"expand_structured_data":false,"timezone":"NotSet"},"title":"Day 3 Lab","global":true,"node":"42397cba-d8b3-444a-b818-a4dc4213511e"}'

# Create Firewall Stream
#curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/streams" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d  '{"index_set_id":"68d5655daf97a6672c363eb1","description":"Firewall Logs","title":"Firewall Stream","remove_matches_from_default_stream":true}'

# Start new Firewall Stream:
#curl -k -u 'admin:yabba dabba doo' -XPOST "https://localhost/api/streams/68d5655daf97a6672c363eb1/resume" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome'

echo "Complete!" 