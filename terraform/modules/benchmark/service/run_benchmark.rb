# frozen_string_literal: true

require 'net/http'
require 'time'
require_relative 'ruby_common/slack_client'
require_relative 'ruby_common/utils'
require 'logger'
require 'fileutils'
require 'date'

# Retrieves an environmental variable, failing if its not set or empty.
def get_and_assert_env_variable(name)
  var = ENV.fetch(name, nil)
  raise "Please set #{name} environmental variable" if var.nil? || var.empty?

  var
end

def prune_logs(dir)
  # Time in seconds for retaining a log file
  seven_days_in_secs = (24 * 3600) * 7

  all_logs = Dir["#{dir}/*"]
  all_logs.each do |path|
    File.delete(path) if (Time.now - File.stat(path).mtime) > seven_days_in_secs
  end
end

SLACK_TOKEN = get_and_assert_env_variable 'SLACK_API_TOKEN'
CHANNEL = get_and_assert_env_variable 'SLACK_NOTIF_CHANNEL'
BASE_FOLDER = get_and_assert_env_variable 'BASE_FOLDER'
SCRIPTS_DIR = get_and_assert_env_variable 'BASE_FOLDER'
LOG_DIR = "#{BASE_FOLDER}/logs"
BENCHMARK_BUCKET = get_and_assert_env_variable 'BENCHMARK_BUCKET'
BENCHMARK_ENDPOINT = get_and_assert_env_variable 'BENCHMARK_ENDPOINT'

def file_last_modified_date
  file_url = "https://#{BENCHMARK_BUCKET}.#{BENCHMARK_ENDPOINT}/benchmark-results/all-results.csv"
  response = Net::HTTP.get_response(URI(file_url))
  Time.parse(response['last-modified']).to_date
end

loop do
  # Current datetime, to append to the log files
  datetime = Time.new.strftime '%FT%H:%M:%S'
  run_log = "#{LOG_DIR}/benchmark_#{datetime}_run"
  report_log = "#{LOG_DIR}/benchmark_#{datetime}_report"

  # Create log directory
  FileUtils.mkdir_p LOG_DIR

  logger = Logger.new(report_log)

  logger.info 'Running the benchmark...'
  benchmark_check_passed = system("bash #{SCRIPTS_DIR}/run_benchmark.sh > #{run_log} 2>&1")
  logger.info 'Benchmark run completed'

  client = SlackClient.new CHANNEL, SLACK_TOKEN

  if benchmark_check_passed
    # Send Slack notification only if today's date differs from the last notification date
    client.post_message '✅ Benchmark run was successful. 🌲🌳🌲🌳🌲' unless Date.today == file_last_modified_date
  else
    client.post_message '⛔ Benchmark run fiascoed. 🔥🌲🔥'
  end

  client.attach_files(run_log, report_log)
  logger.info 'Benchmark finished'
  prune_logs(LOG_DIR)
end
