#!/bin/bash

dnf install -y docker ruby ruby-devel s3cmd wget 
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
mkdir --parents -- "$BASE_FOLDER/forest_db/filops"

chmod +x ./upload_filops_snapshot.sh

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
EOF

# Add the New Relic infrastructure monitoring agent repository to the system's list of yum repos.
# The resulting file (/etc/yum.repos.d/newrelic-infra.repo) is used by yum to locate the New Relic packages.
# While dnf is the preferred package manager for Fedora, we are using yum here because 
# New Relic does not officially support Fedora but provides packages for CentOS/RHEL.
# Using yum increases the likelihood of correctly handling these RHEL/CentOS-based packages.
sudo curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/el/9/x86_64/newrelic-infra.repo

# Refreshes the New Relic repository. This step ensures that yum is aware of the latest versions of available packages.
sudo yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'

# Installs the New Relic infrastructure agent. This package provides the monitoring functionality needed.
sudo yum install newrelic-infra -y

