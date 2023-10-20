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

#Powershell
printf "\n\nSetting up local log tooling"
sudo wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update -y
sudo apt-get install powershell -y

#Move "sendlogs" to default profile
sudo mkdir /home/ubuntu/.config/powershell -p
sudo mv /tmp/local_log_tooling/Default_Profile.ps1 /home/ubuntu/.config/powershell/Microsoft.PowerShell_profile.ps1
sudo mkdir /home/ubuntu/powershell/Data -p
sudo mv /tmp/local_log_tooling/Data/* /home/ubuntu/powershell/Data
sudo chown -R ubuntu.ubuntu /home/ubuntu

#Tar OliveTin Install
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
sudo chown -R root.root /OliveTin-linux-amd64/
sed -i '/^Restart=always.*/a User=root' /OliveTin-linux-amd64/OliveTin.service
sudo systemctl link /OliveTin-linux-amd64/OliveTin.service
sudo systemctl enable OliveTin.service
#wget https://raw.githubusercontent.com/Graylog2/graylog-training-data/main/Gj95F7HnyYCZDsQP9/configs/olivetin/config.yaml
#mv config.yaml /etc/OliveTin/config.yaml


#Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin openjdk-17-jre-headless

wget https://raw.githubusercontent.com/graylog-labs/graylog-playground/main/autogl/docker-compose.yml
sudo docker compose -f docker-compose.yml pull -q
sudo docker compose -f docker-compose.yml create
sudo docker compose -f docker-compose.yml up -d


##Repos
sudo apt install git-svn -y



