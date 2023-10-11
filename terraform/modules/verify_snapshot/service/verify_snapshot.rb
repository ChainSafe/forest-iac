# frozen_string_literal: true

require_relative 'ruby_common/slack_client'
require_relative 'ruby_common/docker_utils'
require_relative 'ruby_common/utils'

require 'date'
require 'logger'
require 'fileutils'
require 'active_support/time'

BASE_FOLDER = get_and_assert_env_variable 'BASE_FOLDER'
SLACK_TOKEN = get_and_assert_env_variable 'SLACK_API_TOKEN'
CHANNEL = get_and_assert_env_variable 'SLACK_NOTIF_CHANNEL'

# Current datetime, to append to the log files
DATE = Time.new.strftime '%FT%H:%M:%S'
LOG_EXPORT_SCRIPT_RUN = "mainnet_#{DATE}_script_run.txt"

client = SlackClient.new CHANNEL, SLACK_TOKEN


# conditionally add timestamps to logs without timestamps
add_timestamps_cmd = "awk '{ if ($0 !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\.[0-9]{6}Z/) print strftime(\"[%Y-%m-%d %H:%M:%S]\"), $0; else print $0; fflush(); }'"

# Sync and export snapshot
snapshot_uploaded = system("bash -c 'timeout --signal=KILL 24h ./verify_snapshot.sh' | #{add_timestamps_cmd} > #{LOG_EXPORT_SCRIPT_RUN} 2>&1")

if snapshot_uploaded
  puts "✅ Verification of Mainnet Snapshot Successful. 🌲🌳🌲🌳🌲"
else
  client.post_message "⛔ Verification of Mainnet Snapshot failed. 🔥🌲🔥 "
  # attach the log file and print the contents to STDOUT
  client.attach_files(LOG_EXPORT_SCRIPT_RUN)
end
