# Avoids warnings during package installations
export DEBIAN_FRONTEND=noninteractive
source /etc/profile

#Add Docker Repo
printf "\n\n$(date)-Adding Docker Repo\n"
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq
printf "\n\n$(date)-Adding keyring dir\n"
sudo mkdir -p /etc/apt/keyrings
printf "\n\n$(date)-$(date)adding gpg key\n"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
printf "\n\n$(date)-adding repo to apt\n"
printf "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
cat /etc/apt/sources.list.d/docker.list

#Install Software
printf "\n\n$(date)-Installing Software\n"
sudo mkdir /etc/graylog
sudo apt update
sudo apt upgrade -y

#Powershell
printf "\n\n$(date)-Setting up local log tooling"
sudo wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update -y
sudo apt-get install powershell -y

#Move "sendlogs" to default profile
sudo mkdir /root/.config/powershell -p
sudo mv /common/scripts/Default_Profile.ps1 /root/.config/powershell/Microsoft.PowerShell_profile.ps1
sudo mkdir /root/powershell/Data -p

#Tar OliveTin Install
printf "\n\n$(date)-Setting up OliveTin"
sudo wget https://github.com/OliveTin/OliveTin/releases/download/2023.03.25/OliveTin-linux-amd64.tar.gz -O /tmp/OliveTin-linux-amd64.tar.gz
sudo tar -xf /tmp/OliveTin-linux-amd64.tar.gz -C /
sudo mkdir /var/www/ -p
sudo ln -s /OliveTin-linux-amd64/OliveTin /usr/local/bin/OliveTin
sudo ln -s /OliveTin-linux-amd64 /etc/OliveTin
sudo ln -s /OliveTin-linux-amd64/webui /var/www/olivetin

#Update service file to use Ubuntu user and get it running
printf "\n\n$(date)-Configure OT to use OT user"
sudo chown -R root.root /OliveTin-linux-amd64/
sed -i '/^Restart=always.*/a User=root' /OliveTin-linux-amd64/OliveTin.service
sudo systemctl link /OliveTin-linux-amd64/OliveTin.service
sudo systemctl enable OliveTin.service

#Docker
printf "\n\n$(date)-Install Docker"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin openjdk-17-jre-headless

printf "\n\n$(date)-Grab and get containers running"
wget https://raw.githubusercontent.com/Graylog2/graylog-training-data/main/instruqt/common/configs/docker-compose-glservices.yml
wget https://raw.githubusercontent.com/Graylog2/graylog-training-data/main/instruqt/common/configs/graylog-training-changes.env
sudo docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env pull -q
sudo docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env create
sudo docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env start mongodb

printf "\n\n$(date)-Complete Base Setup -> Running class config"

#Class Config
printf "\n\n$(date)-Grab Class Data"
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/instruqt/$CLASS"
sudo mv $CLASS /$CLASS
sudo chmod +x /$CLASS/scripts/*.sh

#Update OliveTin Configuration File
sudo rm /OliveTin-linux-amd64/config.yaml
sudo mv /$CLASS/configs/olivetin/config.yaml /OliveTin-linux-amd64/config.yaml

printf "\n\n$(date)-Starting Class Config Script"
./$CLASS/scripts/config.sh

printf "\n\n$(date)-100% Complete. Locked and loaded"