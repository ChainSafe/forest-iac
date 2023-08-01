#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

# Create a new user with a home directory, no password (SSH login only), and no gecos info.
adduser --disabled-password --gecos "" "$USER"

# Set up SSH for the new user.
mkdir --parents -- "/home/$USER/.ssh"
chown "$USER:$USER" "/home/$USER/.ssh"
chmod 0700 "/home/$USER/.ssh"

# Inherit authorized_keys from root, if they exist, to allow the same key-based access for the new user.
if [ -f "/root/.ssh/authorized_keys" ]; then
  : Allowing those with root ssh keys to log in as "$USER"
  cp /root/.ssh/authorized_keys "/home/$USER/.ssh/authorized_keys"
  chown "$USER:$USER" "/home/$USER/.ssh/authorized_keys"
  chmod 0600 "/home/$USER/.ssh/authorized_keys"
fi

# Add new user to "sudo" and "docker" group so they can run docker commands and have general admin rights.
usermod --append --groups sudo,docker "$USER"

## Install dependencies
dnf install -y dnf-plugins-core docker docker-compose ruby ruby-devel gcc make && \
  dnf clean all
gem install slack-ruby-client sys-filesystem

sudo --user="$USER" -- \
  nohup /bin/bash ./run_service.sh > run_service_log.txt &

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
