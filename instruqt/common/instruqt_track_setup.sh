set -eo pipefail
export DEBIAN_FRONTEND=noninteractive

# Set License Details
cluster_id=${cluster_id}
license_enterprise=${license_enterprise}
license_security=${license_security}
gn_api_key=${gn_api_key}
authemail=${cloudflare_auth_email}
apitoken=${cloudflare_auth_token}
dns=${HOSTNAME}-${_SANDBOX_ID}

echo "export cluster_id=$cluster_id" >> /etc/profile
echo "export license_enterprise=$license_enterprise" >> /etc/profile
echo "export license_security=$license_security" >> /etc/profile
echo "export gn_api_key=$gn_api_key" >> /etc/profile
echo "export apitoken=$apitoken" >> /etc/profile
echo "export authemail=$authemail" >> /etc/profile
echo "export dns=$dns" >> /etc/profile

# Setup Class Information
CLASS="analyst"
TITLE="Graylog Analyst"
echo "export CLASS=$CLASS" >> /etc/profile
echo "export TITLE=$TITLE" >> /etc/profile

# Uncomment below if this course needs a Graylog Docker environment:
echo "export NEEDS_DOCKER=yes" >> /etc/profile

# Cert Decode File
echo "${cert_pwd}" > /root/.pwd

# Base Apps
printf "\n\nGrabbing Base Apps"
sudo apt update
sudo apt install git-svn -y

# common Scripts
printf "\n\nGrabbing Common Scripts"
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/instruqt/common"
sudo mv common /common
sudo chmod +x /common/*.sh

# Run Base Install
printf "\n\nRunning Base Install"
/common/base_setup.sh