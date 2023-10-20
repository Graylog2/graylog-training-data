#!/bin/bash
#load Vars from Strigo
source /etc/profile

#Illuminate Install
./common/inst_illuminate.sh 

#Course Settings
./common/course_settings.sh 

#Add course CPs
./common/cp_inst.sh 

#Update GL Docker Environment
## After this point everything will be HTTPS
./common/docker_chg.sh 

#OT Theme
./common/ot_gl_theme.sh 

#Cleanup
./common/cleanup.sh 

echo "Complete!" 