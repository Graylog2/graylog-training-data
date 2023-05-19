#NCAT handles UDP better
sudo apt install ncat -y

#Update OT Config
mv /home/ubuntu/GIT/GIM/configs/olivetin/config.yml /OliveTin-linux-amd64/config.yml
sudo systemctl restart OliveTin.service