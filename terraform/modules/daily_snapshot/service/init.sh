#!/bin/bash

set -eux 

# Use an active loop to wait for the apt package system to become available.
# This is done to handle any ongoing system boot operations, especially apt tasks,
# and ensure that the initialization doesn't collide with other apt processes.
timeout=15 # Set a maximum waiting time of 5 seconds
interval=5  # Check the apt lock status every 5 seconds

while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    sleep $interval
    timeout=$((timeout - interval))

    if [ $timeout -le 0 ]; then
        echo "Timed out waiting for apt to become available."
        exit 1
    fi
done

apt-get update && apt-get install -y ruby ruby-dev s3cmd anacron
gem install docker-api slack-ruby-client activesupport 

# 1. Configure s3cmd
# 2. create forest_db directory
# 3. Copy scripts to /etc/cron.hourly

## Configure s3cmd
s3cmd --dump-config \
    --host="$SNAPSHOT_ENDPOINT" \
    --host-bucket="%(bucket)s.$SNAPSHOT_ENDPOINT" \
    --access_key="$AWS_ACCESS_KEY_ID" \
    --secret_key="$AWS_SECRET_ACCESS_KEY" \
    --multipart-chunk-size-mb=4096 > ~/.s3cfg

## Create forest data directory
mkdir forest_db
chmod 777 forest_db
mkdir --parents -- "$BASE_FOLDER/forest_db/filops"

# make the scripts executable
chmod +x ./upload_filops_snapshot.sh

# run new_relic and fail2ban scripts
bash newrelic_fail2ban.sh &

# Setup cron jobs
cp calibnet_cron_job mainnet_cron_job /etc/cron.hourly/

