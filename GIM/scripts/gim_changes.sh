#NCAT handles UDP better
sudo apt install ncat -y

#Update OT Config
mv /home/ubuntu/GIT/GIM/configs/olivetin/config.yaml /OliveTin-linux-amd64/config.yaml
sudo systemctl restart OliveTin.service