# frozen_string_literal: true

require_relative 'ruby_common/slack_client'
require_relative 'ruby_common/docker_utils'
require_relative 'ruby_common/utils'

require 'date'
require 'logger'
require 'fileutils'

SLACK_TOKEN = get_and_assert_env_variable 'SLACK_API_TOKEN'
CHANNEL = get_and_assert_env_variable 'SLACK_NOTIFICATION_CHANNEL'

CHAIN_NAME = ARGV[0]
raise 'No chain name supplied. Please provide chain identifier, e.g. calibnet or mainnet' if ARGV.empty?

# Current datetime, to append to the log files
DATE = Time.new.strftime '%FT%H:%M:%S'

FileUtils.mkdir_p 'logs'
LOG_EXPORT_SCRIPT_RUN = "logs/#{CHAIN_NAME}_#{DATE}_script_run.txt"
LOG_EXPORT_DAEMON = "logs/#{CHAIN_NAME}_#{DATE}_daemon.txt"
LOG_EXPORT_METRICS = "logs/#{CHAIN_NAME}_#{DATE}_metrics.txt"

client = SlackClient.new CHANNEL, SLACK_TOKEN
logger = Logger.new($stdout)

# conditionally add timestamps to logs without timestamps
add_timestamps_cmd = <<~CMD
  awk '{
  if ($0 !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{6}Z/)
    print strftime("[%Y-%m-%d %H:%M:%S]"), $0;
  else
    print $0;
  fflush();
  }'
CMD

upload_cmd = <<~CMD.chomp
  set -o pipefail && \
  timeout -s SIGKILL 8h ./upload_snapshot.sh #{CHAIN_NAME} #{LOG_EXPORT_DAEMON} #{LOG_EXPORT_METRICS} | \
  #{add_timestamps_cmd}
CMD

# The command needs to be run indirectly to avoid syntax errors in the shell.
logger.info "Running snapshot export script for #{CHAIN_NAME}..."
snapshot_uploaded = system('bash', '-c', upload_cmd, %i[out err] => LOG_EXPORT_SCRIPT_RUN)
logger.info "Snapshot export script finished for #{CHAIN_NAME}."

if snapshot_uploaded
  # This log message is important, as it is used by the monitoring tools to determine whether the snapshot was
  # successfully uploaded.
  logger.info "Snapshot uploaded for #{CHAIN_NAME}."
else
  logger.error "Snapshot upload failed for #{CHAIN_NAME}."
  client.post_message "⛔ Snapshot failed for #{CHAIN_NAME}. 🔥🌲🔥 "
  # attach the log file and print the contents to STDOUT
  [LOG_EXPORT_SCRIPT_RUN, LOG_EXPORT_DAEMON, LOG_EXPORT_METRICS].each do |log_file|
    client.attach_files(log_file) if File.exist?(log_file)
  end
end

[LOG_EXPORT_SCRIPT_RUN, LOG_EXPORT_DAEMON, LOG_EXPORT_METRICS].each do |log_file|
  logger.info "Snapshot export log:\n#{File.read(log_file)}\n\n" if File.exist?(log_file)
end
