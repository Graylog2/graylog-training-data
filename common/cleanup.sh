#!/bin/bash
#load Vars from Strigo
source /etc/profile

#Cleanup
echo "Cleaning up" >> /home/$LUSER/strigosuccess
sed -i '/export apitoken=/d' /etc/profile
sed -i '/export authemail=/d' /etc/profile
rm -r /certs
rm -r /$STRIGO_CLASS_ID

echo "Complete!" >> /home/$LUSER/strigosuccess