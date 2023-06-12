#!/bin/bash
clear
printf "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m ::::::::  :::    ::: ::::::::::     ::: ::::::::::: :::::::::: ::::::::: \n" 
printf "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m:+:    :+: :+:    :+: :+:          :+: :+:   :+:     :+:        :+:    :+:\n" 
printf "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m+:+        +:+    +:+ +:+         +:+   +:+  +:+     +:+        +:+    +:+\n" 
printf "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m+#+        +#++:++#++ +#++:++#   +#++:++#++: +#+     +#++:++#   +#++:++#: \n" 
printf "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m+#+        +#+    +#+ +#+        +#+     +#+ +#+     +#+        +#+    +#+\n" 
printf "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m#+#    #+# #+#    #+# #+#        #+#     #+# #+#     #+#        #+#    #+#\n" 
printf "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m ########  ###    ### ########## ###     ### ###     ########## ###    ###\n\e[39m" 

printf "You cheater.  Oh well, its here for a reason. :) \n\n"
printf " * * * * Mongo Cluster * * * * \n"
printf "\e[3$(( $RANDOM * 6 / 32767 + 1 ))mmongosh --eval \'rs.add(\"${STRIGO_RESOURCE_0_DNS}\")\'\n\n"
printf "mongosh --eval \'rs.add(\"${STRIGO_RESOURCE_1_DNS}\")\'\n\n"
printf "\e[39m * * * * opensearch.yml  * * * \n"
printf "\e[3$(( $RANDOM * 6 / 32767 + 1 ))mdiscovery.seed_hosts: [${STRIGO_RESOURCE_0_DNS},${STRIGO_RESOURCE_1_DNS},${STRIGO_RESOURCE_2_DNS}]\n\n"
printf "\e[39m * * * * server.conf * * * * * \n"
printf "\e[3$(( $RANDOM * 6 / 32767 + 1 ))melasticsearch_hosts = http://${STRIGO_RESOURCE_0_DNS}:9200,http://${STRIGO_RESOURCE_1_DNS}:9200,http://${STRIGO_RESOURCE_2_DNS}\n\n"
printf "mongodb_uri = mongodb://${STRIGO_RESOURCE_0_DNS}:27017,${STRIGO_RESOURCE_1_DNS}:27017,${STRIGO_RESOURCE_2_DNS}:27017/graylog?replicaSet=rs0\n\n\e[39m"
