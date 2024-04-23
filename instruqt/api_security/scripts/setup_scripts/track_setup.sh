# Instruqt Track Setup Lifecycle script.
# First script ran during course initialization.
# ref: https://graylogdocumentation.atlassian.net/wiki/x/Q4A9t

### Script Setup ###

# Set script to exit on any non-zero exit code and display extra debug info (per Instruqt's recommendation):
set -exo pipefail

# To reduce issues with user prompts during package installation:
export DEBIAN_FRONTEND=noninteractive
echo "export DEBIAN_FRONTEND=noninteractive" >> /etc/profile

# Setup Class Information
# CLASS should be lowercase and match track's folder name in repo:
CLASS="api_security"
# TITLE should match "pretty" track name in Instruqt and 
# should use caps and spaces:
TITLE="Intro to Graylog API Security"
echo "export CLASS=$CLASS" >> /etc/profile
echo "export TITLE=$TITLE" >> /etc/profile

# Base Apps
printf "\n=== Upgrading Base Packages ===\n"
# Add Docker repository to Apt sources list:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get -y upgrade

# Import files from repo:
printf "\n=== Grabbing Scripts from Repo ===\n"
git clone --depth 1 https://github.com/Graylog2/graylog-training-data.git /graylog-training-data
mkdir -p /common/
mv /graylog-training-data/instruqt/common/* /common/
sudo chmod +x /common/*.sh
rm -rf /graylog-training-data

# Install Resurface:
printf "\n=== Deploying Resurface ===\n"
docker run -d --name resurface -p 7700:7700 -p 7701:7701 --memory=10g -e DB_SIZE=4g -e DB_HEAP=6g -e POLLING_CYCLE=fast resurfaceio/resurface:3.6.72

# Get # days difference between date in events (2024-01-09) and today's date:
DATE_DIFF=$(( ($(date +%s) - $(date --date="20240109" +%s) )/(60*60*24) ))

# Create Dataset with appropriate date range
sudo java -DTRANSFORM_DUPLICATES=drop -DTRANSFORM_RESPONSE_TIME_MILLIS=add:"$DATE_DIFF"d -DFILES_IN=/common/resurface_common/training-coinbroker-2024-01-09.ndjson.gz,/common/resurface_common/training-honeypot-2024-01-09.ndjson.gz -DFILE_OUT=/common/resurface_common/results.ndjson.gz -Xmx192M -jar /common/resurface_common/resurfaceio-transformer-3.6.3.jar

# Send api calls:
printf "\n=== Importing Honeypot Data into Resurface ===\n"
java -DFILE=/common/resurface_common/results.ndjson.gz -DHOST=localhost -DPORT=7701 -DLIMIT_MESSAGES=0 -DLIMIT_MILLIS=0 -DREPEAT=no -DSATURATED_STOP=no -Xmx512M -jar /common/resurface_common/resurfaceio-importer-3.5.3.jar

# Install license:
printf "\n=== Applying License ===\n"
curl -X POST --user 'autolicense:' --data ''"create or replace view resurface.settings.license_key security invoker as select * from (values ('${gapis_license}')) as licenseKey (value)"'' "http://localhost:7700/ui/api/resurface/runsql"

# Wait for UI to become available:
printf "\n=== Waiting for UI to become available... ===\n"
while [ "$(curl http://localhost:7700/ui/login.html?/ui/resurface/ -I -s | head -n1 | cut -d$' ' -f2)" != 200 ]
do sleep 1
done

# Cleanup
printf "\n=== Running Cleanup ===\n"
/common/cleanup.sh