#!/bin/bash

set -eux

# Wait for cloud-init to finish initializing the machine
cloud-init status --wait

# Setting DEBIAN_FRONTEND to ensure non-interactive operations for APT
export DEBIAN_FRONTEND=noninteractive

# Using timeout to ensure the script retries if the APT servers are temporarily unavailable.
timeout 10m bash -c 'until apt-get -qqq --yes update && \
 apt-get -qqq --yes install anacron ; do sleep 10; \
done'

# Run new_relic and fail2ban scripts
bash newrelic_fail2ban.sh

# Setup cron jobs
cp calibnet_cron_job mainnet_cron_job /etc/cron.hourly/
