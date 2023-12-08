#!/bin/bash
#load Vars from Strigo
source /etc/profile

#LogData
sudo mv /$CLASS/log_data/* /root/powershell/Data
sudo chown -R root.root /root
mkdir /home/ubuntu/pipeline_rules
sudo mv /$CLASS/pipeline_rules/* /home/ubuntu/pipeline_rules

#DNS
/common/dns.sh 

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
/common/docker_chg.sh

#Illuminate Install - moved to POST docker update. Illuminate doesn't seem to fetch first time graylog runs
/common/inst_illuminate.sh 

#Cleanup
/common/cleanup.sh 

echo "Complete!" 