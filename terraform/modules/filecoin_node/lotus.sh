#!/bin/bash

# This bash script is used to initialize a Lotus Mainnet or Calibnet Droplet.
# It starts the chain (either mainnet or calibnet) as specified in the terraform script.
# The script also runs Watchtower to keep the Lotus Docker images up-to-date,
# and sets up the New Relic agent for system monitoring.

# The script employs Terraform's templating engine, which uses variables defined in terraform.tfvars.
# Thus, the $${VARIABLES} used here are for the template engine, not BASH.

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

# Restrict SSH access to the new user only. preventing root user from accessing the system via SSH.
echo "AllowUsers ${NEW_USER}" >> /etc/ssh/sshd_config
systemctl restart sshd

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
  --env LOTUS_CHAINSTORE_SPLITSTORE_COLDSTORETYPE="discard" \
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

cat >> /etc/newrelic-infra.yml <<EOF
display_name: lotus-${CHAIN}
override_hostname_short: lotus-${CHAIN}
EOF
  sudo systemctl restart newrelic-infra
fi
