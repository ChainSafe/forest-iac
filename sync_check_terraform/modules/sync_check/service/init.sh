#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

## Install dependencies
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && \
dnf install -y dnf-plugins-core docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose ruby ruby-devel gcc make && \
dnf clean all
gem install slack-ruby-client sys-filesystem

nohup /bin/bash ./run_service.sh > run_service_log.txt &

# Set-up the New Relic license key and custom configuration
cat << EOF | sudo tee -a /etc/newrelic-infra.yml
enable_process_metrics: true
status_server_enabled: true
status_server_port: 18003
license_key: "$NR_LICENSE_KEY"
custom_attributes:
  nr_deployed_by: newrelic-cli
display_name: "$NAME"
EOF

# Adding the  New Relic infrastructure monitoring agent repository
sudo curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/el/9/x86_64/newrelic-infra.repo

# Refresh the the new relic repository
sudo yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'

# Install the new relic infrastructure agent
sudo yum install newrelic-infra -y
