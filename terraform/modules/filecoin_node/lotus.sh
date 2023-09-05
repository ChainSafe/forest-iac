#!/bin/bash

# This bash script is used to initialize a Lotus Mainnet or Calibnet Droplet.
# It starts the chain (either mainnet or calibnet) as specified in the terraform script.
# The script also runs Watchtower to keep the Lotus Docker images up-to-date,
# and sets up the New Relic agent for system monitoring.

# The script employs Terraform's templating engine, which uses variables defined in terraform.tfvars.
# therefore, variables like ${NEW_USER} used here are intended for the template engine, not BASH

set -euxo pipefail

# Create a new user with a home directory, no password (SSH login only), and no gecos info.
adduser --disabled-password --gecos "" "${NEW_USER}"

# Set up SSH for the new user.
mkdir --parents -- "/home/${NEW_USER}/.ssh"
chown "${NEW_USER}:${NEW_USER}" "/home/${NEW_USER}/.ssh"
chmod 0700 "/home/${NEW_USER}/.ssh"

# Inherit authorized_keys from root, if they exist, to allow the same key-based access for the new user.
if [ -f "/root/.ssh/authorized_keys" ]; then
  : Allowing those with root ssh keys to log in as "${NEW_USER}"
  cp /root/.ssh/authorized_keys "/home/${NEW_USER}/.ssh/authorized_keys"
  chown "${NEW_USER}:${NEW_USER}" "/home/${NEW_USER}/.ssh/authorized_keys"
  chmod 0600 "/home/${NEW_USER}/.ssh/authorized_keys"
fi

#install NTP to synchronize the time differences
sudo DEBIAN_FRONTEND=noninteractive apt-get -qqq --yes -o DPkg::Lock::Timeout=-1 install -y ntp

# Enable passwordless sudo for the new user. This allows the user to run sudo commands without being prompted for a password.
echo "${NEW_USER} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/"${NEW_USER}"

# Add new user to "docker" group so they can run docker commands
usermod --append --groups docker "${NEW_USER}"

# Set up the directory where the lotus container will store its data.
mkdir --parents -- "/home/${NEW_USER}/lotus_data"

# If a volume name is defined, mount the volume to the lotus_data directory.
if [ -n "${VOLUME_NAME}" ]; then
  # discard: notify the volume to free blocks (useful for SSDs)
  # defaults: default mount options, including rw
  # noatime: don't preserve file access times
  : mounting volume at the lotus_data directory
  mount --options discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_"${DISK_ID_VOLUME_NAME}" "/home/${NEW_USER}/lotus_data"
fi

# Change the ownership of the lotus_data directory to the created user.
chown --recursive "${NEW_USER}":"${NEW_USER}" "/home/${NEW_USER}/lotus_data"

IMAGETAG="stable"

if [ "${CHAIN}" != "mainnet" ]; then
  IMAGETAG="stable-calibnet"
fi

sudo --user="${NEW_USER}" -- docker network create lotus

# Run the Lotus Docker container as the created user.
sudo --user="${NEW_USER}" -- \
  docker run \
  --detach \
  --network=lotus \
  --name=lotus-"${CHAIN}" \
  --env LOTUS_CHAIN_BADGERSTORE_DISABLE_FSYNC=true \
  --env LOTUS_CHAINSTORE_SPLITSTORE_COLDSTORETYPE="discard" \
  --env LOTUS_CHAINSTORE_SPLITSTORE_HOTSTOREFULLGCFREQUENCY=1 \
  --volume=parameters:/var/tmp/filecoin-proof-parameters \
  --volume=/home/"${NEW_USER}"/lotus_data:/var/lib/lotus \
  --publish=1234:1234 \
  --restart=always \
  filecoin/lotus-all-in-one:"$IMAGETAG" lotus daemon \
  --import-snapshot https://snapshots."${CHAIN}".filops.net/minimal/latest.zst

# It monitors running Docker containers and watches for changes to the images that those containers were originally started from.
# If Watchtower detects that an image has changed, it will automatically restart the container using the new image.
# Run the Watchtower Docker container as created user.
sudo --user="${NEW_USER}" -- \
  docker run \
  --detach \
  --network=lotus \
  --name=watchtower \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --restart=unless-stopped \
  containrrr/watchtower \
  --include-stopped --revive-stopped --stop-timeout 120s --interval 600

# If New Relic license key and API key are provided,
# install the new relic agent and New relic agent and OpenMetrics Prometheus integration.
if [ -n "${NEW_RELIC_API_KEY}" ]; then
  curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && \
  sudo  NEW_RELIC_API_KEY="${NEW_RELIC_API_KEY}" \
  NEW_RELIC_ACCOUNT_ID="${NEW_RELIC_ACCOUNT_ID}" \
  NEW_RELIC_REGION="${NEW_RELIC_REGION}" \
  /usr/local/bin/newrelic install -y

# The provided configurations are specific to New Relic. To gain a deeper understanding of these configuration details, you can visit:
# https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/configuration/infrastructure-agent-configuration-settings/#offline-time-to-reset
cat >> /etc/newrelic-infra.yml <<EOF
include_matching_metrics:
  process.name:
    - regex "^lotus-mainnet.*"
    - regex "^fail2ban.*"
    - regex "^rsyslog.*"
    - regex "^syslog.*"
    - regex "^gpg-agent.*"
metrics_network_sample_rate: -1
metrics_process_sample_rate: 600
metrics_system_sample_rate: 600
metrics_storage_sample_rate: 600
metrics_nfs_sample_rate: 600
container_cache_metadata_limit: 600
disable_zero_mem_process_filter: true
disable_all_plugins: true
disable_cloud_metadata: true
ignore_system_proxy: true
EOF

  sudo systemctl restart newrelic-infra
fi

#set-up fail2ban with the default configuration
sudo DEBIAN_FRONTEND=noninteractive apt-get -qqq --yes -o DPkg::Lock::Timeout=-1 install -y fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban && sudo systemctl start fail2ban
