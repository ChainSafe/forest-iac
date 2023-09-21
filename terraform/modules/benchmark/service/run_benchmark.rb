# frozen_string_literal: true

require 'net/http'
require 'time'
require_relative 'ruby_common/slack_client'
require_relative 'ruby_common/utils'
require 'logger'
require 'fileutils'
require 'date'

def get_and_assert_env_variable(name)
  var = ENV.fetch(name, nil)
  raise "Please set #{name} environmental variable" if var.nil? || var.empty?

  var
end

def file_last_modified_date
  file_url = 'https://forest-benchmarks.fra1.digitaloceanspaces.com/benchmark-results/all-results.csv'
  response = Net::HTTP.get_response(URI(file_url))
  Time.parse(response['last-modified']).to_date
end

SLACK_TOKEN = get_and_assert_env_variable 'SLACK_API_TOKEN'
CHANNEL = get_and_assert_env_variable 'SLACK_NOTIF_CHANNEL'
SCRIPTS_DIR = get_and_assert_env_variable 'BASE_FOLDER'
LOG_DIR = get_and_assert_env_variable 'BASE_FOLDER'

loop do
  datetime = Time.new.strftime '%FT%H:%M:%S'
  run_log = "#{LOG_DIR}/benchmark_#{datetime}_run"
  report_log = "#{LOG_DIR}/benchmark_#{datetime}_report"

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
end
