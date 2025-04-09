#cloud-config
package_update: true
package_upgrade: true

packages:
  - ruby
  - ruby-dev
  - gcc
  - make
  - fail2ban

write_files:
  # Environment variables for the service. It will be loaded by systemd.
  - path: /etc/restart.conf
    content: |
      FOREST_TARGET_DATA="${FOREST_TARGET_DATA}"
      FOREST_TARGET_SCRIPTS="${FOREST_TARGET_SCRIPTS}"
      FOREST_TARGET_RUBY_COMMON="${FOREST_TARGET_RUBY_COMMON}"
      FOREST_SLACK_API_TOKEN="${slack_token}"
      FOREST_SLACK_NOTIF_CHANNEL="${slack_channel}"
      NEW_RELIC_API_KEY="${NEW_RELIC_API_KEY}"
      NEW_RELIC_ACCOUNT_ID="${NEW_RELIC_ACCOUNT_ID}"
      NEW_RELIC_REGION="${NEW_RELIC_REGION}"
      FOREST_TAG="${forest_tag}"
  
runcmd:
  - "tar xf /root/sources.tar -C /root"
  - "gem install slack-ruby-client sys-filesystem --no-document"
  - "bash /root/install_newrelic.sh"
  - "cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local"
  - "systemctl enable fail2ban"
  - "systemctl start fail2ban"
  - "cp /root/restart.service /etc/systemd/system/"
  - "systemctl enable restart.service"
  - "systemctl start restart.service"

final_message: "Sync check setup completed!"
