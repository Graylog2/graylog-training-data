#!/bin/bash
cat <<EOF >> /home/admin/.bashrc
printf "\e[37m ██████╗ ██████╗  █████╗ ██╗   ██╗\e[31m██╗      ██████╗  ██████╗ \n";
printf "\e[37m██╔════╝ ██╔══██╗██╔══██╗╚██╗ ██╔╝\e[31m██║     ██╔═══██╗██╔════╝ \n";
printf "\e[37m██║  ███╗██████╔╝███████║ ╚████╔╝ \e[31m██║     ██║   ██║██║  ███╗\n";
printf "\e[37m██║   ██║██╔══██╗██╔══██║  ╚██╔╝  \e[31m██║     ██║   ██║██║   ██║\n";
printf "\e[37m╚██████╔╝██║  ██║██║  ██║   ██║   \e[31m███████╗╚██████╔╝╚██████╔╝\n";
printf "\e[37m ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   \e[31m╚══════╝ ╚═════╝  ╚═════╝ \n";
printf "                                                            \n";
printf "\e[39m${STRIGO_RESOURCE_0_NAME}\t\e[93m${STRIGO_RESOURCE_0_DNS}\n\n";
printf "\e[39m${STRIGO_RESOURCE_1_NAME}\t\e[93m${STRIGO_RESOURCE_1_DNS}\n\n";
printf "\e[39m${STRIGO_RESOURCE_2_NAME}\t\e[93m${STRIGO_RESOURCE_2_DNS}\n\n";
printf "\e[39m${STRIGO_RESOURCE_3_NAME}\t\e[93m${STRIGO_RESOURCE_3_DNS}\n\n";

printf "\e[39m  Hi ${STRIGO_USER_NAME},\n Welcome to ${STRIGO_CLASS_NAME}\n\n";
EOF