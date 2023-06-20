#!/bin/bash

# 1. Enable strict error handling, command tracing, and pipefail
# 2. Start docker daemon and create required shared volumes
# 3. Ensure watchtower is running
# 4. Copy all relevant scripts to shared volumes
# 5. Run health check for mainnet and calibnet 

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

## Start docker daemon
systemctl start docker

## Setup volume
docker volume create --name=forest-data
docker volume create --name=sync-check
docker volume create --name=ruby-common

## Kill all relevant containers
docker container rm --force watchtower 2> /dev/null || true
docker container rm --force forest-calibnet 2> /dev/null || true
docker container rm --force forest-mainnet 2> /dev/null || true
docker container rm --force forest-tester 2> /dev/null || true

## Ensure watchtower is running
docker stop watchtower 2> /dev/null || true
docker wait watchtower 2> /dev/null || true
docker run \
    --detach \
    --restart unless-stopped \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --name watchtower \
    containrrr/watchtower \
    --label-enable --include-stopped --revive-stopped --stop-timeout 120s --interval 600

## We need it to access the DATA_DIR regardless of the user.
chmod 0777 /var/lib/docker/volumes/forest-data/_data

## Ensure volumes are clean
rm -rf /var/lib/docker/volumes/forest-data/_data/*
rm -rf /var/lib/docker/volumes/sync-check/_data/*
rm -rf /var/lib/docker/volumes/ruby-common/_data/*

## Copy all relevant scripts
cp --recursive /root/* /var/lib/docker/volumes/sync-check/_data/
cp --recursive /root/ruby_common/* /var/lib/docker/volumes/ruby-common/_data/

## Run health check status of a running node
ruby sync_check_process.rb

# Set-up the New Relic license key
cat << EOF | sudo tee -a /etc/newrelic-infra.yml
enable_process_metrics: true
status_server_enabled: true
status_server_port: 18003
license_key: $NR_LICENSE_KEY
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
