#!/bin/bash

set -eux

# Wait for cloud-init to finish initializing the machine
cloud-init status --wait

# Setting DEBIAN_FRONTEND to ensure non-interactive operations for APT
export DEBIAN_FRONTEND=noninteractive

# https://www.digitalocean.com/community/tutorials/how-to-set-up-time-synchronization-on-ubuntu-20-04
# We will install the NTP service, so we need to disable the `systemd-timesyncd`.
# This is to prevent the two services from conflicting with one another.
timedatectl set-ntp no

# Using timeout to ensure the script retries if the APT servers are temporarily unavailable.
timeout 10m bash -c 'until apt-get -qqq --yes update && \
 apt-get -qqq --yes install anacron ntp ; do sleep 10; \
done'

# Run new_relic and fail2ban scripts
bash newrelic_fail2ban.sh

echo "$SNAPSHOT_TYPE"

# Setup cron job
IFS=',' read -ra ADDR <<< "$SNAPSHOT_TYPE"
for type in "${ADDR[@]}"; do
  case "$type" in
    mainnet)
      mv mainnet_cron_job /etc/cron.hourly/
      ;;
    calibnet)
      mv calibnet_cron_job /etc/cron.hourly/
      ;;
    *)
      echo "Error: Invalid network type '$type'"
      ;;
  esac
done
