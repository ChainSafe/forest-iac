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
cp calibnet_cron_job mainnet_cron_job /etc/cron.hourly/

# Set-up the New Relic license key and custom configuration
cat << EOF | sudo tee -a /etc/newrelic-infra.yml
enable_process_metrics: true
status_server_enabled: true
status_server_port: 18003
license_key: "$NR_LICENSE_KEY"
custom_attributes:
  nr_deployed_by: newrelic-cli
display_name: "$NAME"
EOF

# Adding the  New Relic infrastructure monitoring agent repository
sudo curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/el/9/x86_64/newrelic-infra.repo

# Refresh the the new relic repository
sudo yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'

# Install the new relic infrastructure agent
sudo yum install newrelic-infra -y
