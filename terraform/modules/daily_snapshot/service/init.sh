#!/bin/bash

set -eux

# Wait for cloud-init to finish initializing the machine
cloud-init status --wait

# Setting DEBIAN_FRONTEND to ensure non-interactive operations for APT
export DEBIAN_FRONTEND=noninteractive

# Using timeout to ensure the script retries if the APT servers are temporarily unavailable.
timeout 10m bash -c 'until apt-get -qqq --yes update && \
 apt-get -qqq --yes install ruby ruby-dev anacron awscli; do sleep 10; \
done'

# Install the gems
gem install docker-api slack-ruby-client
gem install activesupport -v 7.0.8

# 1. Configure aws
# 2. Create forest_db directory
# 3. Copy scripts to /etc/cron.hourly

## Configure aws
aws configure set default.s3.multipart_chunksize 4GB
aws configure set aws_access_key_id "$R2_ACCESS_KEY"
aws configure set aws_secret_access_key "$R2_SECRET_KEY"

## Create forest data directory
mkdir forest_db logs
chmod 777 forest_db logs
mkdir --parents -- "$BASE_FOLDER/forest_db/filops"

# Make the scripts executable
chmod +x ./upload_filops_snapshot.sh

# Run new_relic and fail2ban scripts
bash newrelic_fail2ban.sh &

# Setup cron jobs
cp calibnet_cron_job mainnet_cron_job /etc/cron.hourly/
