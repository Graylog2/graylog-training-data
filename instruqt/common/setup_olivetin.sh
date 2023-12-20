#!/bin/bash

# Configure Powershell and Olivetin for use in log replay

# Import env vars used throughout scripts runtime
source /etc/profile

#Powershell
printf "\n\n$(date)-Installing Powershell for use with Olive-Tin\n"
sudo wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update -y
sudo apt-get install powershell -y

#Move "sendlogs" to default profile
sudo mkdir /root/.config/powershell -p
sudo mv /common/Default_Profile.ps1 /root/.config/powershell/Microsoft.PowerShell_profile.ps1
sudo mkdir /root/powershell/Data -p

#Tar OliveTin Install
printf "\n\n$(date)-Setting up OliveTin\n"
sudo wget https://github.com/OliveTin/OliveTin/releases/download/2023.03.25/OliveTin-linux-amd64.tar.gz -O /tmp/OliveTin-linux-amd64.tar.gz
sudo tar -xf /tmp/OliveTin-linux-amd64.tar.gz -C /
sudo mkdir /var/www/ -p
sudo ln -s /OliveTin-linux-amd64/OliveTin /usr/local/bin/OliveTin
sudo ln -s /OliveTin-linux-amd64 /etc/OliveTin
sudo ln -s /OliveTin-linux-amd64/webui /var/www/olivetin

#Update OliveTin Configuration File
sudo rm /OliveTin-linux-amd64/config.yaml
sudo mv /common/configs/config.yaml /OliveTin-linux-amd64/config.yaml

#Update service file to use Ubuntu user and get it running
printf "\n\n$(date)-Configure OT to use OT user\n"
sudo chown -R root.root /OliveTin-linux-amd64/
sed -i '/^Restart=always.*/a User=root' /OliveTin-linux-amd64/OliveTin.service
sudo systemctl link /OliveTin-linux-amd64/OliveTin.service
sudo systemctl enable OliveTin.service