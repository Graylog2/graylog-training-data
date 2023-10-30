#!/bin/bash
#load Vars from Strigo
source /etc/profile

#LogData
sudo mv /$CLASS/log_data/* /root/powershell/Data
sudo chown -R root.root /root

#Illuminate Install
/common/inst_illuminate.sh 

#Course Settings
/common/course_settings.sh 

#Add course CPs
/common/cp_inst.sh 

#Update GL Docker Environment
/common/docker_chg.sh 

#OT Theme
/common/ot_gl_theme.sh 

#Cleanup
/common/cleanup.sh 

echo "Complete!" 