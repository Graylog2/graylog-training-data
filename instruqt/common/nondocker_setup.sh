#!/bin/bash

# This script is only for courses that don't
# utilize Graylog in a Docker environment.

# Avoids warnings during package installations:
export DEBIAN_FRONTEND=noninteractive
source /etc/profile

# Import Class folder from repo:
printf "\n\n$(date)-Grab Class Data\n"
git svn clone "https://github.com/Graylog2/graylog-training-data/trunk/instruqt/$CLASS"

printf printf "\n\n$(date)-Move Class Data and make exec\n"
sudo mv $CLASS /$CLASS
sudo chmod +x /$CLASS/scripts/*.sh

printf "\n\n$(date)-Starting Class Config Script\n"
/$CLASS/scripts/config.sh

printf "\n\n$(date)-Complete. Locked and loaded\n"