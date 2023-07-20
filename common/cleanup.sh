#!/bin/bash
#load Vars from Strigo
source /etc/profile

#Cleanup
echo "Cleaning up" >> /home/$LUSER/strigosuccess
sed -i '/export apitoken=/d' /etc/profile
sed -i '/export authemail=/d' /etc/profile
rm -r /certs
rm /.pwd
rm -r /$STRIGO_CLASS_ID
rm -r /common

echo "Cleanup complete!" >> /home/$LUSER/strigosuccess