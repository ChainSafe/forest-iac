#!/bin/bash

set -eux

# Setting DEBIAN_FRONTEND to ensure non-interactive operations for APT
export DEBIAN_FRONTEND=noninteractive

# Use APT specific mechanism to wait for the lock
apt-get -qqq --yes -o DPkg::Lock::Timeout=90 update
apt-get -qqq --yes -o DPkg::Lock::Timeout=90 install -y ruby ruby-dev anacron awscli

# Install the gems
gem install docker-api slack-ruby-client activesupport

# 1. Configure aws
# 2. Create forest_db directory
# 3. Copy scripts to /etc/cron.hourly

## Configure aws
aws configure set default.s3.multipart_chunksize 4GB
aws configure set aws_access_key_id "$R2_ACCESS_KEY"
aws configure set aws_secret_access_key "$R2_SECRET_KEY"

## Create forest data directory
mkdir forest_db
chmod 777 forest_db
mkdir --parents -- "$BASE_FOLDER/forest_db/filops"

# Make the scripts executable
chmod +x ./upload_filops_snapshot.sh

# Run new_relic and fail2ban scripts
bash newrelic_fail2ban.sh &

# Setup cron jobs
cp calibnet_cron_job mainnet_cron_job /etc/cron.hourly/
