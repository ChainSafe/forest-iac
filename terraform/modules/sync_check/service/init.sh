#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

## Install dependencies
apt-get install -y docker docker-compose ruby ruby-dev gcc make && \
  apt clean
gem install slack-ruby-client sys-filesystem

nohup /bin/bash ./run_service.sh > run_service_log.txt &

# If new relic API key is provided, install the new relic agent
if [ -n "${NEW_RELIC_API_KEY}" ] ; then
  curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && \
  sudo  NEW_RELIC_API_KEY="${NEW_RELIC_API_KEY}" \
  NEW_RELIC_ACCOUNT_ID="${NEW_RELIC_ACCOUNT_ID}" \
  NEW_RELIC_REGION="${NEW_RELIC_REGION}" \
  /usr/local/bin/newrelic install -y
fi 

#set-up fail2ban with the default configuration
sudo apt-get install fail2ban -y
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban && sudo systemctl start fail2ban
