# Avoids warnings during package installations
export DEBIAN_FRONTEND=noninteractive

#Add Docker Repo
printf "\n\nAdding Docker Repo\n"
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq
printf "\n\nAdding keyring dir\n"
sudo mkdir -p /etc/apt/keyrings
printf "\n\nadding gpg key\n"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
printf "\n\nadding repo to apt\n"
printf "\n\ndeb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
cat /etc/apt/sources.list.d/docker.list

#Install Software
printf "\n\nInstalling Software\n"
sudo apt update
sudo apt upgrade -y

#Pull Class Data
printf "\n\nGrab Class Data"
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/$CLASS"
sudo mv ~/$CLASS /$CLASS
sudo chmod +x /$CLASS/scripts/*.sh

#Powershell
printf "\n\nSetting up local log tooling"
sudo wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update -y
sudo apt-get install powershell -y

#Move "sendlogs" to default profile
sudo mkdir /root/.config/powershell -p
sudo mv /common/scripts/Default_Profile.ps1 /root/.config/powershell/Microsoft.PowerShell_profile.ps1
sudo mkdir /root/powershell/Data -p
sudo mv /$CLASS/log_data/* /root/powershell/Data
sudo chown -R root.root /root

#Tar OliveTin Install
printf "\n\nSetting up OliveTin"
sudo wget https://github.com/OliveTin/OliveTin/releases/download/2023.03.25/OliveTin-linux-amd64.tar.gz -O /tmp/OliveTin-linux-amd64.tar.gz
sudo tar -xf /tmp/OliveTin-linux-amd64.tar.gz -C /
sudo mkdir /var/www/ -p
sudo ln -s /OliveTin-linux-amd64/OliveTin /usr/local/bin/OliveTin
sudo ln -s /OliveTin-linux-amd64 /etc/OliveTin
sudo ln -s /OliveTin-linux-amd64/webui /var/www/olivetin

#Update OliveTin Configuration File
sudo rm /OliveTin-linux-amd64/config.yaml
sudo mv /tmp/local_log_tooling/config.yml /OliveTin-linux-amd64/config.yaml

#Update service file to use Ubuntu user and get it running
printf "\n\nConfigure OT to use OT user"
sudo chown -R root.root /OliveTin-linux-amd64/
sed -i '/^Restart=always.*/a User=root' /OliveTin-linux-amd64/OliveTin.service
sudo systemctl link /OliveTin-linux-amd64/OliveTin.service
sudo systemctl enable OliveTin.service
#wget https://raw.githubusercontent.com/Graylog2/graylog-training-data/main/Gj95F7HnyYCZDsQP9/configs/olivetin/config.yaml
#mv config.yaml /etc/OliveTin/config.yaml

#Docker
printf "\n\nInstall Docker"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin openjdk-17-jre-headless

printf "\n\nGrab and get containers running"
wget https://raw.githubusercontent.com/Graylog2/graylog-training-data/main/instruqt/common/configs/docker-compose-glservices.yml

sudo docker compose -f docker-compose-glservices.yml --env-file strigo-graylog-training-changes.env pull -q
sudo docker compose -f docker-compose-glservices.yml --env-file strigo-graylog-training-changes.env create
sudo docker compose -f docker-compose-glservices.yml --env-file strigo-graylog-training-changes.env start mongodb









