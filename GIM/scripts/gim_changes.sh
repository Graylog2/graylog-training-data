#NCAT handles UDP better
sudo apt install ncat -y

#Clone course changes
git clone https://github.com/Graylog2/graylog-training-data.git /home/ubuntu/GIT

#Update OT Config
mv /home/ubuntu/GIT/GIM/configs/olivetin/config.yml /OliveTin-linux-amd64/config.yml
sudo systemctl restart OliveTin.service