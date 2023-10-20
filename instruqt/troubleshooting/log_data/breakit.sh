#!/usr/bin/bash

for (( i=0; i<50; i++ )); do cat /etc/graylog/log_data/004-mf.log | nc -w 1 localhost 5060; done