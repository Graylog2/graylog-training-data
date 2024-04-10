#!/bin/bash

# Import env vars used throughout scripts runtime
source /etc/profile

# Setup OliveTin:
/common/setup_olivetin.sh

# Setup Greynoise:
/common/setup_greynoise.sh

# Setup Maxmind GeoIP databases:
/common/setup_geoip.sh

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

#Temp switch to latest GL Version
lgl=$(curl -L --fail "https://hub.docker.com/v2/repositories/graylog/graylog/tags/?page_size=1000" | jq '.results | .[] | .name' -r | sed 's/latest//' | sort --version-sort | tail -n 1)
dcv=$(sed -n 's/image: "graylog\/graylog-enterprise://p' docker-compose-glservices.yml | tr -d '"' | tr -d " ")
sed -i "s+enterprise\:$dcv+enterprise\:$lgl+g" docker-compose-glservices.yml
docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env up -d

echo "Complete!" 