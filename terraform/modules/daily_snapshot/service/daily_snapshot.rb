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

# Query the date of the most recent snapshot.
def latest_snapshot_date(chain_name = 'calibnet')
  # We do not support HEAD requests but we _do_ support empty ranges.
  filename = `curl --remote-name --remote-header-name --write-out "%{filename_effective}" --silent https://forest-archive.chainsafe.dev/latest/#{chain_name}/ -H "Range: bytes=0-0"`
  # Curl will create a file with a single byte in it. Let's clean it up.
  File.delete(filename)
  snapshot_format = /^([^_]+?)_snapshot_(?<network>[^_]+?)_(?<date>\d{4}-\d{2}-\d{2})_height_(?<height>\d+)(\.forest)?\.car.zst$/
  filename.match(snapshot_format) do |m|
    m[:date].to_date
  end
end


CHAIN_NAME = ARGV[0]
raise 'No chain name supplied. Please provide chain identifier, e.g. calibnet or mainnet' if ARGV.empty?

# Current datetime, to append to the log files
DATE = Time.new.strftime '%FT%H:%M:%S'
LOG_EXPORT = "#{CHAIN_NAME}_#{DATE}_export.txt"

client = SlackClient.new CHANNEL, SLACK_TOKEN

# Query the date of the most recent snapshot. This is used to limit the number
# of victory messages to 1/day even if we upload multiple snapshots per day.
date_before_export = latest_snapshot_date(CHAIN_NAME)

# Sync and export snapshot
snapshot_uploaded = system("bash -c 'timeout --signal=KILL 24h ./upload_snapshot.sh #{CHAIN_NAME}' > #{LOG_EXPORT} 2>&1")

if snapshot_uploaded
  date_after_export = latest_snapshot_date(CHAIN_NAME)

  # If this is the first new snapshot of the day, send a victory message to slack
  unless date_before_export == date_after_export
    client.post_message "✅ Snapshot uploaded for #{CHAIN_NAME}. 🌲🌳🌲🌳🌲"
  end
else
  client.post_message "⛔ Snapshot failed for #{CHAIN_NAME}. 🔥🌲🔥 "
  # attach the log file and print the contents to STDOUT
  client.attach_files(LOG_EXPORT)
end

puts "Snapshot export log:\n#{File.read(LOG_EXPORT)}"
