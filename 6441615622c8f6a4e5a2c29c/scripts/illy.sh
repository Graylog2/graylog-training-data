#!/bin/bash
while read x; do echo $x"\0" | ncat localhost 12201 -w50ms; done < /etc/graylog/log_data/illy-gelf.log

cat /etc/graylog/log_data/illy-syslog.log | sed "s/datetime/$(date +"%Y-%m-%dT%H:%M:%S%:z")/g" | ncat -w 1 localhost 1514
