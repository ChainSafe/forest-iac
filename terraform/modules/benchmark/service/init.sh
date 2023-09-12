#!/bin/bash

## Enable strict error handling
set -eux

sudo docker build -t benchmark .

echo "Starting benchmark docker service.."
sudo docker run --detach \
  --name forest-benchmark \
  --env AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  --env AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  --env BENCHMARK_BUCKET="$BENCHMARK_BUCKET" \
  --env BENCHMARK_ENDPOINT="$BENCHMARK_ENDPOINT" \
  --env BASE_FOLDER="$BASE_FOLDER" \
  --env SLACK_API_TOKEN="$SLACK_API_TOKEN" \
  --env SLACK_NOTIF_CHANNEL="$SLACK_NOTIF_CHANNEL" \
  --restart unless-stopped \
  benchmark \
  /bin/bash -c "ruby run_benchmark.rb"

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
