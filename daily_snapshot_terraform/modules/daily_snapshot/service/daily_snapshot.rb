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
LOG_EXPORT = "#{CHAIN_NAME}_#{DATE}_export.txt"

SNAPSHOTS_DIR = File.join(BASE_FOLDER, 's3', CHAIN_NAME)

client = SlackClient.new CHANNEL, SLACK_TOKEN

# Find the snapshot with the most recent modification date
all_snapshots = list_snapshots(CHAIN_NAME, BUCKET, ENDPOINT)
unless all_snapshots.empty?
  latest = all_snapshots.first

  # Sync and export snapshot
  snapshot_uploaded = system("bash upload_snapshot.sh #{CHAIN_NAME} #{latest.url} > #{LOG_EXPORT} 2>&1")

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
    client.attach_files(LOG_EXPORT)
  end

  puts "Snapshot export log:\n#{File.read(LOG_EXPORT)}"
  prune_snapshots(all_snapshots)
end
