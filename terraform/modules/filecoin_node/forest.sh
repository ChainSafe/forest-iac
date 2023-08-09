#!/bin/bash

# This bash script is used to initialize a Forest Mainnet or Calibnet Droplet.
# It starts the chain (either mainnet or calibnet) as specified in the terraform script.
# The script also runs Watchtower to keep the Forest Docker images up-to-date,
# and sets up the New Relic agent and openMetrics prometheus for system monitoring and prometheus metrics.

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

systemctl restart sshd

# Add new user to "sudo" and "docker" group so they can run docker commands and have general admin rights.
usermod --append --groups sudo,docker "${NEW_USER}"

# Set up the directory where the Forest container will store its data.
mkdir --parents -- "/home/${NEW_USER}/forest_data"

# Change the ownership of the forest_data directory to the created user.
chown --recursive "${NEW_USER}":"${NEW_USER}" "/home/${NEW_USER}/forest_data"

# Create the config.toml file in the forest_data directory.
cat << EOF > "/home/${NEW_USER}/forest_data/config.toml"
[client]
data_dir = "/home/${NEW_USER}/forest_data"
EOF

sudo --user="${NEW_USER}" -- docker network create forest

# Run the Forest Docker container as the created user.
sudo --user="${NEW_USER}" -- \
  docker run \
  --detach \
  --network=forest \
  --name=forest-"${CHAIN}" \
  --volume=/home/"${NEW_USER}"/forest_data:/home/"${NEW_USER}"/forest_data:z \
  --publish=1234:1234 \
  --publish=6116:6116 \
  --restart=always \
  ghcr.io/chainsafe/forest:latest \
  --config=/home/"${NEW_USER}"/forest_data/config.toml \
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

# If new relic API key is provided, install the new relic agent
if [ -n "${NEW_RELIC_API_KEY}" ] ; then
  curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && \
  sudo  NEW_RELIC_API_KEY="${NEW_RELIC_API_KEY}" \
  NEW_RELIC_ACCOUNT_ID="${NEW_RELIC_ACCOUNT_ID}" \
  NEW_RELIC_REGION="${NEW_RELIC_REGION}" \
  /usr/local/bin/newrelic install -y

cat >> /etc/newrelic-infra.yml <<EOF
include_matching_metrics:
  process.name:
    - regex "^forest.*"
    - regex "^fail2ban.*"
    - regex "^rsyslog.*"
    - regex "^syslog.*"
    - regex "^gpg-agent.*"
metrics_network_sample_rate: 300
metrics_process_sample_rate: 300
metrics_system_sample_rate: 300
disable_all_plugins: true
disable_cloud_metadata: true 
EOF

  sudo systemctl restart newrelic-infra  
fi

# If New Relic license key is provided, run OpenMetrics Prometheus integration container.
if [ -n "${NR_LICENSE_KEY}" ]; then
cat > "/home/${NEW_USER}/forest_data/config.yml" <<EOF
cluster_name: forest-${CHAIN}
targets:
  - description: Forest "${CHAIN}" Prometheus Endpoint
    urls: ["forest-${CHAIN}:6116"]
scrape_interval: 300s
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

#set-up fail2ban with the default configuration
sudo apt-get install fail2ban -y
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban && sudo systemctl start fail2ban
