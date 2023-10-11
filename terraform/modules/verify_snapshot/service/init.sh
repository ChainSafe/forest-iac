#!/bin/bash

set -eux

# Wait for cloud-init to finish initializing the machine
cloud-init status --wait

# Setting DEBIAN_FRONTEND to ensure non-interactive operations for APT
export DEBIAN_FRONTEND=noninteractive

# Use APT specific mechanism to wait for the lock
apt-get -qqq --yes update
apt-get -qqq --yes install -y ruby ruby-dev anacron awscli zstd

# Install the gems
gem install docker-api slack-ruby-client
gem install activesupport -v 7.0.8

apt-get update && apt-get install -y zstd

mkdir snapshot
chmod 777 snapshot

cp verify_snapshot_cron_job /etc/cron.hourly/
