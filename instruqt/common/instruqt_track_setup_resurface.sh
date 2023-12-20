set -eo pipefail
export DEBIAN_FRONTEND=noninteractive

# Setup Class Information
# CLASS should be lowercase and match track's folder name in repo:
CLASS="api-security-intro"
# TITLE should match "pretty" track name in Instruqt and 
# should use caps and spaces:
TITLE="Intro to Graylog API Security"
echo "export CLASS=$CLASS" >> /etc/profile
echo "export TITLE=$TITLE" >> /etc/profile

# Base Apps
printf "\n=== Grabbing Base Apps ==="
apt-get update
apt-get install git-svn -y

# common Scripts
printf "\n=== Grabbing Common Scripts==="
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/instruqt/common"
mv common /common

# Import pre-generated Resurface databases from repo
printf "\n=== Importing Resurface Database ==="
cp /common/resurface_db.tar /root
tar xvf /root/resurface_db.tar > /dev/null
mv /root/db /root/resurface_db

# Add Docker's official GPG key:
printf "\n=== Installing Docker ==="
apt-get update
apt-get install -y ca-certificates curl gnupg openjdk-17-jre-headless
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

# Install Docker:
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Resurface:
# Note: Using non-latest .28 version bc .30 has a UI bug
printf "\n===  Deploying Resurface ==="
docker run -v /root/resurface_db:/db -d --name resurface -p 7700:7700 -p 7701:7701 --memory=10g --restart=always -e DB_SIZE=4g -e DB_HEAP=6g resurfaceio/resurface:3.6.28

# Download the simulator and importer programs:
printf "\n===  Downloading Resurface Simulator and Importer Programs ==="
wget https://dl.cloudsmith.io/public/resurfaceio/public/maven/io/resurface/resurfaceio-simulator/3.5.7/resurfaceio-simulator-3.5.7.jar
wget https://dl.cloudsmith.io/public/resurfaceio/public/maven/io/resurface/resurfaceio-importer/3.5.3/resurfaceio-importer-3.5.3.jar