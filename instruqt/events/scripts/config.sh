#!/bin/bash

# Import env vars used throughout scripts runtime
source /etc/profile

# Setup OliveTin:
/common/setup_olivetin.sh

# TESTING - change timestamps from nanoseconds to microseconds for GELF compliance,
# and to potentially help with Events timing issues.
# GELF Spec says timestamp should be Unix epoch seconds, optionally plus microseconds as decimals.
# ref: GELF Payload Specification: https://archivedocs.graylog.org/en/latest/pages/gelf.html#gelf-payload-specification
#sed -i 's/  /root/.config/powershell/Microsoft.PowerShell_profile.ps1'

# Setup Greynoise:
/common/setup_greynoise.sh

# Setup Maxmind GeoIP databases:
/common/setup_geoip.sh

# LogData
sudo mv /$CLASS/log_data/* /root/powershell/Data
sudo chown -R root.root /root
sudo mkdir -p /etc/graylog/log_data
sudo mv /root/powershell/Data/firewall.log /etc/graylog/log_data/
sudo mv /root/powershell/Data/kvp.log /etc/graylog/log_data/

# Creating Indices
printf "\n\n$(date)-Create Training Index\n"
curl -u 'admin:yabba dabba doo' -XPOST 'http://localhost:9000/api/system/indices/index_sets' -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"title":"Training","description":"Training","index_prefix":"train","writable":true,"can_be_default":true,"shards":2,"replicas":0,"retention_strategy_class":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategy","retention_strategy":{"max_number_of_indices":3,"type":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategyConfig"},"index_analyzer":"standard","index_optimization_max_num_segments":1,"index_optimization_disabled":false,"field_type_refresh_interval":5000,"rotation_strategy_class":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategy","rotation_strategy":{"max_docs_per_index":20000,"type":"org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategyConfig"},"creation_date":"2022-08-17T21:06:47.393Z"}'

# Cert Injection
/common/certs.sh

# Course Settings
/common/course_settings.sh 

# Add course CPs
/common/cp_inst.sh 

#OT Theme
/common/ot_gl_theme.sh 

# Update GL Docker Environment
## After this point everything will be HTTPS
/common/docker_graylog_https.sh

# Illuminate Install - moved to POST docker update. Illuminate doesnt seem to fetch first time graylog runs
/common/inst_illuminate.sh 

# Deploy webhook test container:
docker run -p 8080:8080 -d --restart always tarampampam/webhook-tester

# Deploy maildev container for SMTP testing:
docker run -p 1080:1080 -p 1025:1025 -d maildev/maildev

echo "Complete!" 