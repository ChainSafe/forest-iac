#!/bin/bash

dnf install -y docker ruby ruby-devel s3cmd
gem install docker-api slack-ruby-client activesupport

systemctl start docker

# 1. Configure s3cmd
# 2. Mount volume at 'forest_db'
# 3. Copy scripts to /etc/cron.hourly

## Configure s3cmd
s3cmd --dump-config \
    --host="$SNAPSHOT_ENDPOINT" \
    --host-bucket="%(bucket)s.$SNAPSHOT_ENDPOINT" \
    --access_key="$AWS_ACCESS_KEY_ID" \
    --secret_key="$AWS_SECRET_ACCESS_KEY" \
    --multipart-chunk-size-mb=4096 > ~/.s3cfg

## Setup volume
mkdir forest_db
mount -o defaults,nofail,discard,noatime /dev/disk/by-id/scsi-0DO_Volume_snapshot-gen-storage forest_db
chmod 777 forest_db

# Setup cron jobs
cp calibnet_cron_job /etc/cron.hourly/
cp mainnet_cron_job /etc/cron.hourly/
