#!/bin/bash
# This is simple basic script to install new relic infrastruture agent

set -euo pipefail

# Setting DEBIAN_FRONTEND to ensure non-interactive operations for APT
export DEBIAN_FRONTEND=noninteractive


# Add New Relic's repository
curl -fsSL https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/newrelic-infra.gpg
echo "deb https://download.newrelic.com/infrastructure_agent/linux/apt focal main" | sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list

# Check if NR_LICENSE_KEY is set, if not ask for it
if [[ -z "${NR_LICENSE_KEY:-}" ]]; then
    read -rp "Please enter your NR_LICENSE_KEY: " NR_LICENSE_KEY
fi

# Update the package list
sudo apt-get update

# The provided configurations are specific to New Relic. To gain a deeper understanding of these configuration details, you can visit:
# https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/configuration/infrastructure-agent-configuration-settings/#offline-time-to-reset
cat >> /etc/newrelic-infra.yml <<EOF
enable_process_metrics: true
status_server_enabled: true
status_server_port: 18003
license_key: "$NR_LICENSE_KEY"
custom_attributes:
  nr_deployed_by: newrelic-cli
metrics_network_sample_rate: -1
metrics_process_sample_rate: -1
metrics_system_sample_rate: 600
metrics_storage_sample_rate: 600
metrics_nfs_sample_rate: 600
container_cache_metadata_limit: 600
disable_zero_mem_process_filter: true
disable_all_plugins: true
disable_cloud_metadata: true
ignore_system_proxy: true
EOF

# Install the New Relic Infrastructure Agent
sudo NRIA_MODE="UNPRIVILEGED" apt-get install libcap2-bin newrelic-infra -y
