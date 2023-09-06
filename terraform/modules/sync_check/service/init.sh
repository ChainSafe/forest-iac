#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -eux

DEBIAN_FRONTEND=noninteractive

# Use APT specific mechanism to ensure non-interactive operation and wait for the lock
sudo apt-get -qqq --yes -o DPkg::Lock::Timeout=30 update
sudo apt-get -qqq --yes -o DPkg::Lock::Timeout=30 install -y ruby ruby-dev gcc make

gem install slack-ruby-client sys-filesystem

nohup /bin/bash ./run_service.sh > run_service_log.txt &

if [ -n "$NEW_RELIC_API_KEY" ] ; then
  curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && \
  sudo  NEW_RELIC_API_KEY="$NEW_RELIC_API_KEY" \
  NEW_RELIC_ACCOUNT_ID="$NEW_RELIC_ACCOUNT_ID" \
  NEW_RELIC_REGION="$NEW_RELIC_REGION" \
  /usr/local/bin/newrelic install -y

# The provided configurations are specific to New Relic. To gain a deeper understanding of these configuration details, you can visit:
# https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/configuration/infrastructure-agent-configuration-settings/#offline-time-to-reset
cat >> /etc/newrelic-infra.yml <<EOF
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

cat > /etc/newrelic-infra/logging.d/logging.yml <<EOF
logs:
  - name: alternatives.log
    file: /var/log/alternatives.log
    attributes:
      logtype: linux_alternatives
  - name: auth.log
    file: /var/log/auth.log
    attributes:
      logtype: linux_auth
  - name: newrelic-cli.log
    file: /root/.newrelic/newrelic-cli.log
    attributes:
      newrelic-cli: true
      logtype: newrelic-cli
EOF

  sudo systemctl restart newrelic-infra
fi

#set-up fail2ban with the default configuration
sudo apt-get install fail2ban -y
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban && sudo systemctl start fail2ban
