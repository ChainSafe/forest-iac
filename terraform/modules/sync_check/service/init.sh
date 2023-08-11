#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

## Install dependencies
dnf install -y dnf-plugins-core docker docker-compose ruby ruby-devel gcc make && \
  dnf clean all
gem install slack-ruby-client sys-filesystem

nohup /bin/bash ./run_service.sh > run_service_log.txt &

cat >> /etc/newrelic-infra.yml <<EOF
enable_process_metrics: true
status_server_enabled: true
status_server_port: 18003
license_key: "$NR_LICENSE_KEY"
custom_attributes:
  nr_deployed_by: newrelic-cli

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

#set-up fail2ban with the default configuration
sudo dnf install fail2ban -y
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban && sudo systemctl start fail2ban
