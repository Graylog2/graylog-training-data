#!/bin/bash

# Switch Docker Graylog from HTTP -> HTTPS
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail
# Import env vars used throughout scripts runtime
source /etc/profile

#Update GL Docker Environment
echo "Removing old variables" 
sed -i '/GLEURI=/d' graylog-training-changes.env
sed -i '/GLBINDADDR=/d' graylog-training-changes.env
sed -i '/GLTLS=/d' graylog-training-changes.env

echo "Adding updated variables" 
echo "GLBINDADDR=\"0.0.0.0:443\"" >> graylog-training-changes.env
echo "GLTLS=true" >> graylog-training-changes.env
echo "GLEURI=https://$dns.logfather.org/" >> graylog-training-changes.env

#Launch Docker to load changes in env file
echo "Running Docker Compose to update GL environment with new information" 
docker compose -f docker-compose-glservices.yml --env-file graylog-training-changes.env up -d
