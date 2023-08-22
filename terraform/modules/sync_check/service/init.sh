#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -eux

## Install dependencies
apt-get update && apt-get install -y ruby ruby-dev gcc make
gem install slack-ruby-client sys-filesystem

nohup /bin/bash ./run_service.sh > run_service_log.txt &

if [ -n "$NEW_RELIC_API_KEY" ] ; then
  curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && \
  sudo  NEW_RELIC_API_KEY="$NEW_RELIC_API_KEY" \
  NEW_RELIC_ACCOUNT_ID="$NEW_RELIC_ACCOUNT_ID" \
  NEW_RELIC_REGION="$NEW_RELIC_REGION" \
  /usr/local/bin/newrelic install -y

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
  sudo systemctl restart newrelic-infra 
fi

#set-up fail2ban with the default configuration
sudo apt-get install fail2ban -y
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban && sudo systemctl start fail2ban
