#!/bin/bash
# This script configures New Relic infrastructure monitoring and Fail2Ban.
# It sets up the New Relic license key and custom configuration, adds the New Relic repository,
# refreshes it, and installs the New Relic infrastructure agent.
# It also installs Fail2Ban, sets up its default configuration, and enables it to start at boot

set -euo pipefail

if [ -n "$NR_LICENSE_KEY" ]; then
# Set-up the New Relic license key and custom configuration

cat >> /etc/newrelic-infra.yml <<EOF
enable_process_metrics: true
status_server_enabled: true
status_server_port: 18003
license_key: "$NR_LICENSE_KEY"
custom_attributes:
  nr_deployed_by: newrelic-cli
EOF

cat >> /etc/newrelic-infra.yml <<EOF
include_matching_metrics:
  process.name:
    - regex "^forest.*"
    - regex "^fail2ban.*"
    - regex "^rsyslog.*"
    - regex "^syslog.*"
    - regex "^gpg-agent.*"
metrics_network_sample_rate: -1
metrics_process_sample_rate: 300
metrics_system_sample_rate: 300
metrics_storage_sample_rate: 300
disable_zero_mem_process_filter: true
disable_all_plugins: true
disable_cloud_metadata: true 
ignore_system_proxy: true 
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
fi

#set-up fail2ban with the default configuration
sudo dnf install fail2ban -y
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban && sudo systemctl start fail2ban

