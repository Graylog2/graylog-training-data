set -eo pipefail
export DEBIAN_FRONTEND=noninteractive

#Set License Details
cluster_id=${cluster_id}
license_enterprise=${license_enterprise}
license_security=${license_security}
gn_api_key=${gn_api_key}
echo "export cluster_id=$cluster_id" >> /etc/profile
echo "export license_enterprise=$license_enterprise" >> /etc/profile
echo "export license_security=$license_security" >> /etc/profile
echo "export gn_api_key=$gn_api_key" >> /etc/profile

#Setup Class Information
CLASS="<INSERT CLASS NAME MATCHING FOLDER HERE>"
echo "export CLASS=$CLASS" >> /etc/profile

#Base Apps
printf "\n\nGrabbing Base Apps"
sudo apt update
sudo apt install git-svn -y

#common Scripts
printf "\n\nGrabbing Common Scripts"
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/instruqt/common"
sudo mv common /common
sudo chmod +x /common/*.sh

#Run Base Install
printf "\n\nRunning Base Install"
/common/base_setup.sh