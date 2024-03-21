#!/bin/bash

# Setup script common to all courses.
# ONLY includes commands compatible with all course designs.
# Based on the professional-services-406616/graylog-ubuntu2204 GCP Image
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t



### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile



### Common Host Config ###

# Update all system packages first:
printf "\n\n$(date)-Installing System Updates\n"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -q -y -u -o Dpkg::Options::="--force-confdef" --allow-downgrades --allow-remove-essential --allow-change-held-packages --allow-change-held-packages --allow-unauthenticated

# Setup gpg keyring for apt:
printf "\n\n$(date)-Adding gpg keyring dir for apt\n"
mkdir -p /etc/apt/keyrings

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
printf "\e[39m Hi,\n Welcome to ${TITLE}!\n"
printf "\e[93m Your public DNS record is: https://$dns.logfather.org\n";

EOF

# Minor vim behavior tweak to fix undesireable pasting behavior:
printf "set paste\nsource \$VIMRUNTIME/defaults.vim\n" > ~/.vimrc



### Graylog Install ###

# ref: $NO_DOCKER env var set in Instruqt Track setup script.
# If null (the default), deploy Graylog via Docker Compose.
# If not null, deploy Graylog directly on the host VM.
if [[ $NO_DOCKER ]]; then
    printf "\n\n$(date)-Installing Graylog (non-Docker)\n"
    /common/install_graylog.sh
else
    printf "\n\n$(date)-Installing Graylog (Docker)\n"
    /common/install_graylog_docker.sh
fi

### Graylog, MongoDB, and OpenSearch APIs are all accessible from this point forward! ###

# Install Licenses:
printf "\n\n$(date)-Adding licenses\n"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/plugins/org.graylog.plugins.license/licenses" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "$license_enterprise"
curl -u 'admin:yabba dabba doo' -XPOST "http://localhost:9000/api/plugins/org.graylog.plugins.license/licenses" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d "$license_security"
sleep 15s



#### Training Customizations ###

# Header Badge:
printf "\n\n$(date)-Adding Header Badge\n"
curl -u 'admin:yabba dabba doo' -XPUT "http://localhost:9000/api/system/cluster_config/org.graylog.plugins.customization.HeaderBadge" -H 'Content-Type: application/json' -H 'X-Requested-By: PS_TeamAwesome' -d '{"badge_text":"TRAINING","badge_color":"#1a237e","badge_enable":true}'



### End of Base Setup, Running Class-Specific Setup ###

printf "\n\n$(date)-Complete Base Setup -> Running class config\n"

# Import Class Config
#printf "\n\n$(date)-Grab Class Data\n"
#git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/instruqt/$CLASS"

#printf printf "\n\n$(date)-Move Class Data and make exec\n"
#mv $CLASS /$CLASS
chmod +x /$CLASS/scripts/*.sh

# Execute Class-Specific Setup:
printf "\n\n$(date)-Starting Class Config Script\n"
/$CLASS/scripts/config.sh

# Cleanup
/common/cleanup.sh 

### DONE ###
printf "\n\n$(date)-Complete. Locked and loaded\n"