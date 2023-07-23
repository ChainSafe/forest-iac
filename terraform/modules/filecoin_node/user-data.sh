#!/bin/bash

# This bash script is used to initialize a Forest Mainnet or Calibnet Droplet.
# It starts the chain (either mainnet or calibnet) as specified in the terraform script.
# The script also runs Watchtower to keep the Forest Docker images up-to-date,
# and sets up the New Relic agent and openMetrics prometheus for system monitoring and prometheus metrics.

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

# Add new user to "sudo" and "docker" group so they can run docker commands and have general admin rights.
usermod --append --groups sudo,docker "${NEW_USER}"

# Set up the directory where the Forest container will store its data.
mkdir --parents -- "/home/${NEW_USER}/forest_data"

# If a volume name is defined, mount the volume to the forest_data directory.
if [ -n "${VOLUME_NAME}" ]; then
  # discard: notify the volume to free blocks (useful for SSDs)
  # defaults: default mount options, including rw
  # noatime: don't preserve file access times
  : mounting volume at the forest_data directory
  mount --options discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_"${DISK_ID_VOLUME_NAME}" "/home/${NEW_USER}/forest_data"
fi

# Change the ownership of the forest_data directory to the created user.
chown --recursive "${NEW_USER}":"${NEW_USER}" "/home/${NEW_USER}/forest_data"

# Create the config.toml file in the forest_data directory.
cat << EOF > "/home/${NEW_USER}/forest_data/config.toml"
[client]
data_dir = "/home/${NEW_USER}/data"
EOF


sudo --user="${NEW_USER}" -- docker network create forest

# Run the Forest Docker container as the created user.
sudo --user="${NEW_USER}" -- \
  docker run \
  --detach \
  --network=forest \
  --name=forest-"${CHAIN}" \
  --volume=/home/"${NEW_USER}"/forest_data:/home/"${NEW_USER}"/data \
  --publish=1234:1234 \
  --publish=6116:6116 \
  --restart=always \
  ghcr.io/chainsafe/forest:latest \
  --config=/home/"${NEW_USER}"/data/config.toml \
  --encrypt-keystore false \
  --auto-download-snapshot \
  --chain="${CHAIN}"

# It monitors running Docker containers and watches for changes to the images that those containers were originally started from.
# If Watchtower detects that an image has changed, it will automatically restart the container using the new image.
# Run the Watchtower Docker container as created user.
sudo --user="${NEW_USER}" -- \
  docker run \
  --detach \
  --name=watchtower \
  --network=forest \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --restart=unless-stopped \
  containrrr/watchtower \
  --include-stopped --revive-stopped --stop-timeout 120s --interval 600

# If New Relic license key and API key are provided,
# install the new relic agent and New relic agent and OpenMetrics Prometheus integration.
if [ -n "${NEW_RELIC_API_KEY}" ] || [ -n "${NR_LICENSE_KEY}" ]; then
  curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && \
  sudo  NEW_RELIC_API_KEY="${NEW_RELIC_API_KEY}" \
  NEW_RELIC_ACCOUNT_ID="${NEW_RELIC_ACCOUNT_ID}" \
  NEW_RELIC_REGION="${NEW_RELIC_REGION}" \
  /usr/local/bin/newrelic install -y

cat >> /etc/newrelic-infra.yml <<EOF
display_name: forest-${CHAIN}
override_hostname_short: forest-${CHAIN}
EOF
  sudo systemctl restart newrelic-infra

cat > "/home/${NEW_USER}/forest_data/config.yml" <<EOF
cluster_name: forest-${CHAIN}
targets:
  - description: Forest "${CHAIN}" Prometheus Endpoint
    urls: ["forest-${CHAIN}:6116"]
scrape_interval: 15s
max_concurrency: 10
timeout: 15s
retries: 3
log_level: info
EOF

  sudo --user="${NEW_USER}" -- \
    docker run \
    --detach \
    --network=forest \
    --name=nri-prometheus \
    --env LICENSE_KEY="${NR_LICENSE_KEY}" \
    --volume=/home/"${NEW_USER}"/forest_data/config.yml:/config.yml \
    --restart=unless-stopped \
    newrelic/nri-prometheus:latest \
    --configfile=/config.yml
fi
