#!/bin/bash

printf CHEATER_MONGO_STRING=mongodb_uri\ =\ mongodb://{{ .STRIGO_RESOURCE_0_DNS }}:27017,{{ .STRIGO_RESOURCE_1_DNS }}:27017,{{ .STRIGO_RESOURCE_2_DNS }}:27017/graylog?replicaSet=rs0" >> /etc/profile
printf export CHEATER_OPENSEARCH_STRING=opensearch_uri\ = \