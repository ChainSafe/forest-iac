# frozen_string_literal: true

require_relative 'ruby_common/slack_client'
require_relative 'ruby_common/docker_utils'
require_relative 'ruby_common/utils'
require_relative 'snapshots_prune'
require_relative 'list_snapshots'

require 'date'
require 'logger'
require 'fileutils'
require 'active_support/time'

BASE_FOLDER = get_and_assert_env_variable 'BASE_FOLDER'
SLACK_TOKEN = get_and_assert_env_variable 'SLACK_API_TOKEN'
CHANNEL = get_and_assert_env_variable 'SLACK_NOTIF_CHANNEL'
BUCKET = get_and_assert_env_variable 'SNAPSHOT_BUCKET'
ENDPOINT = get_and_assert_env_variable 'SNAPSHOT_ENDPOINT'

CHAIN_NAME = ARGV[0]
raise 'No chain name supplied. Please provide chain identifier, e.g. calibnet or mainnet' if ARGV.empty?

# Current datetime, to append to the log files
DATE = Time.new.strftime '%FT%H:%M:%S'
LOG_EXPORT_SCRIPT_RUN = "logs/#{CHAIN_NAME}_#{DATE}_script_run.txt"
LOG_EXPORT_DAEMON = "logs/#{CHAIN_NAME}_#{DATE}_daemon.txt"
LOG_EXPORT_BACKGROUND = "logs/#{CHAIN_NAME}_#{DATE}_background_logs.txt"
LOG_EXPORT_METRICS = "logs/#{CHAIN_NAME}_#{DATE}_metrics.txt"

client = SlackClient.new CHANNEL, SLACK_TOKEN

all_snapshots = list_snapshots(CHAIN_NAME, BUCKET, ENDPOINT)
unless all_snapshots.empty?
  # conditionally add timestamps to logs without timestamps using awk
  add_timestamps_cmd = "awk '{ if ($0 !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\.[0-9]{6}Z/) print strftime(\"[%Y-%m-%d %H:%M:%S]\"), $0; else print $0; fflush(); }'"

  # Sync and export snapshot
  snapshot_uploaded = system("bash -c 'timeout --signal=KILL 24h ./upload_snapshot.sh #{CHAIN_NAME} #{LOG_EXPORT_DAEMON} #{LOG_EXPORT_METRICS}' | #{add_timestamps_cmd} > #{LOG_EXPORT_SCRIPT_RUN} 2>&1")

  # Update our list of snapshots
  all_snapshots = list_snapshots(CHAIN_NAME, BUCKET, ENDPOINT)

  if snapshot_uploaded
    # If this is the first new snapshot of the day, send a victory message to slack
    unless all_snapshots[0].date == all_snapshots[1].date
      client.post_message "✅ Snapshot uploaded for #{CHAIN_NAME}. 🌲🌳🌲🌳🌲"
    end
  else
    client.post_message "⛔ Snapshot failed for #{CHAIN_NAME}. 🔥🌲🔥 "
    # attach the log file and print the contents to STDOUT
    [LOG_EXPORT_SCRIPT_RUN, LOG_EXPORT_DAEMON, LOG_EXPORT_METRICS].each do |log_file|
      client.attach_files(log_file) if File.exist?(log_file)
    end
  end

  [LOG_EXPORT_SCRIPT_RUN, LOG_EXPORT_DAEMON, LOG_EXPORT_METRICS].each do |log_file|
    if File.exist?(log_file)
      puts "#{log_file} content:\n#{File.read(log_file)}\n\n"
    else
      puts "#{log_file} does not exist or wasn't created."
    end
  end

  prune_snapshots(all_snapshots)
end
