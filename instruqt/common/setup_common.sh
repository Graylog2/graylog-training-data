#!/bin/bash

# Setup script common to all courses.
# ONLY includes commands compatible with all course designs.
# Assumes an Ubuntu 22.04 GCP Image as Instruqt Sandbox VM



### Env Vars ###

# Avoids warnings during package installations
export DEBIAN_FRONTEND=noninteractive
# Import env vars used throughout scripts runtime
source /etc/profile



### Common Host Config ###

# Update all system packages first:
printf "\n\n$(date)-Installing System Updates\n"
sudo apt upgrade -y

#Install common deps:
printf "\n\n$(date)-Installing common dependencies\n"
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq

# Setup gpg keyring for apt:
printf "\n\n$(date)-Adding gpg keyring dir for apt\n"
sudo mkdir -p /etc/apt/keyrings

# DNS registration (to populate $dns env var):
/common/dns.sh

# Add login banner to bashrc
cat <<EOF >> /root/.bashrc
printf "\e[37m ██████╗ ██████╗  █████╗ ██╗   ██╗\e[31m██╗      ██████╗  ██████╗ \n";
printf "\e[37m██╔════╝ ██╔══██╗██╔══██╗╚██╗ ██╔╝\e[31m██║     ██╔═══██╗██╔════╝ \n";
printf "\e[37m██║  ███╗██████╔╝███████║ ╚████╔╝ \e[31m██║     ██║   ██║██║  ███╗\n";
printf "\e[37m██║   ██║██╔══██╗██╔══██║  ╚██╔╝  \e[31m██║     ██║   ██║██║   ██║\n";
printf "\e[37m╚██████╔╝██║  ██║██║  ██║   ██║   \e[31m███████╗╚██████╔╝╚██████╔╝\n";
printf "\e[37m ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   \e[31m╚══════╝ ╚═════╝  ╚═════╝ \n";
printf "                                                                        \n";
printf "\e[39m Hi,\n Welcome to Graylog ${CLASS}\n\e[93m Your public DNS record is: https://$dns.logfather.org";
printf "                                                                        \n";

EOF

# Minor vim behavior tweak to fix undesireable pasting behavior:
printf "set paste\nsource \$VIMRUNTIME/defaults.vim\n" > ~/.vimrc



### Graylog Install ###

# If course author specified this course needs a Graylog Docker environment configured,
# run the install_graylog_docker.sh script. Else, run install_graylog.sh:
if [[ $NEEDS_DOCKER ]]; then
    printf "\n\n$(date)-Installing Graylog (Docker)\n"
    ./install_graylog_docker.sh
else
    printf "\n\n$(date)-Installing Graylog (non-Docker)\n"
    ./install_graylog.sh
fi

### Graylog, MongoDB, and OpenSearch APIs are all accessible from this point forward! ###

# Install Licenses:
printf "\n\nAdding licenses\n"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/plugins/org.graylog.plugins.license/licenses" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "$license_enterprise"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/plugins/org.graylog.plugins.license/licenses" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "$license_security"
sleep 15s



#### Training Customizations ###

# Header Badge:
printf "\n\nAdding Header Badge\n"
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/cluster_config/org.graylog.plugins.customization.HeaderBadge" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"badge_text":"TRAINING","badge_color":"#1a237e","badge_enable":true}'



### End of Base Setup, Running Class-Specific Setup ###

printf "\n\n$(date)-Complete Base Setup -> Running class config\n"

# Import Class Config
printf "\n\n$(date)-Grab Class Data\n"
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/instruqt/$CLASS"

printf printf "\n\n$(date)-Move Class Data and make exec\n"
sudo mv $CLASS /$CLASS
sudo chmod +x /$CLASS/scripts/*.sh

# Execute Class-Specific Setup:
printf "\n\n$(date)-Starting Class Config Script\n"
/$CLASS/scripts/config.sh



### DONE ###
printf "\n\n$(date)-Complete. Locked and loaded\n"