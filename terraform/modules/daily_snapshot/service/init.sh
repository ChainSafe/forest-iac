#!/bin/bash

apt-get install -y docker ruby ruby-devel s3cmd wget 
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
bash newrelic_fail2ban.sh

# Setup cron jobs
cp calibnet_cron_job mainnet_cron_job /etc/cron.hourly/
