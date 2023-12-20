#!/bin/bash

# Configure Powershell and Olivetin for use in log replay

# Import env vars used throughout scripts runtime
source /etc/profile

#Powershell
printf "\n\n$(date)-Installing Powershell for use with Olive-Tin\n"
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update -y
apt-get install powershell -y

#Move "sendlogs" to default profile
mkdir /root/.config/powershell -p
mv /common/Default_Profile.ps1 /root/.config/powershell/Microsoft.PowerShell_profile.ps1
mkdir /root/powershell/Data -p

#Tar OliveTin Install
printf "\n\n$(date)-Setting up OliveTin\n"
wget https://github.com/OliveTin/OliveTin/releases/download/2023.03.25/OliveTin-linux-amd64.tar.gz -O /tmp/OliveTin-linux-amd64.tar.gz
tar -xf /tmp/OliveTin-linux-amd64.tar.gz -C /
mkdir /var/www/ -p
ln -s /OliveTin-linux-amd64/OliveTin /usr/local/bin/OliveTin
ln -s /OliveTin-linux-amd64 /etc/OliveTin
ln -s /OliveTin-linux-amd64/webui /var/www/olivetin

#Update OliveTin Configuration File
rm /OliveTin-linux-amd64/config.yaml
mv /common/configs/config.yaml /OliveTin-linux-amd64/config.yaml

#Update service file to use Ubuntu user and get it running
printf "\n\n$(date)-Configure OT to use OT user\n"
chown -R root.root /OliveTin-linux-amd64/
sed -i '/^Restart=always.*/a User=root' /OliveTin-linux-amd64/OliveTin.service
systemctl link /OliveTin-linux-amd64/OliveTin.service
systemctl enable OliveTin.service