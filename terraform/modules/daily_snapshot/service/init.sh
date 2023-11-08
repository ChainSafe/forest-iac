#!/bin/bash

set -eux

# Wait for cloud-init to finish initializing the machine
cloud-init status --wait

# Setting DEBIAN_FRONTEND to ensure non-interactive operations for APT
export DEBIAN_FRONTEND=noninteractive

# Use an active loop to wait for the apt package system to become available.
# This is done to handle any ongoing system boot operations, especially apt tasks,
# and ensure that the initialization doesn't collide with other apt processes.
timeout=60 # Set a maximum waiting time of 60 seconds
interval=5  # Check the apt lock status every 5 seconds

while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    sleep $interval
    timeout=$((timeout - interval))

    if [ $timeout -le 0 ]; then
        echo "Timed out waiting for apt to become available."
        exit 1
    fi
done

# Use APT specific mechanism to wait for the lock
apt-get -qqq --yes update
apt-get -qqq --yes install ruby ruby-dev anacron awscli

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
