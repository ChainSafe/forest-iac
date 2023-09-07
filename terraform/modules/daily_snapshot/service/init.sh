#!/bin/bash

set -eux

# Use APT specific mechanism to ensure non-interactive operation and wait for the lock
sudo DEBIAN_FRONTEND=noninteractive apt-get -qqq --yes -o DPkg::Lock::Timeout=-1 update
sudo DEBIAN_FRONTEND=noninteractive apt-get -qqq --yes -o DPkg::Lock::Timeout=-1 install -y ruby ruby-dev s3cmd anacron awscli

# Install the gems
gem install docker-api slack-ruby-client activesupport

# 1. Configure s3cmd
# 2. Create forest_db directory
# 3. Copy scripts to /etc/cron.hourly

## Configure s3cmd
s3cmd --dump-config \
    --host="$SNAPSHOT_ENDPOINT" \
    --host-bucket="%(bucket)s.$SNAPSHOT_ENDPOINT" \
    --access_key="$AWS_ACCESS_KEY_ID" \
    --secret_key="$AWS_SECRET_ACCESS_KEY" \
    --multipart-chunk-size-mb=4096 > ~/.s3cfg

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
