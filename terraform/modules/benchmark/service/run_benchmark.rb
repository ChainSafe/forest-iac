# frozen_string_literal: true

require_relative 'ruby_common/slack_client'
require_relative 'ruby_common/utils'

require 'logger'
require 'fileutils'

# Retrieves an environmental variable, failing if its not set or empty.
def get_and_assert_env_variable(name)
  var = ENV.fetch(name, nil)
  raise "Please set #{name} environmental variable" if var.nil? || var.empty?

  var
end

SLACK_TOKEN = get_and_assert_env_variable 'SLACK_API_TOKEN'
CHANNEL = get_and_assert_env_variable 'SLACK_NOTIF_CHANNEL'
SCRIPTS_DIR = get_and_assert_env_variable 'BASE_FOLDER'
LOG_DIR = get_and_assert_env_variable 'BASE_FOLDER'

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
    client.post_message '✅ Benchmark run was successful. 🌲🌳🌲🌳🌲'
  else
    client.post_message '⛔ Benchmark run fiascoed. 🔥🌲🔥'
  end
  client.attach_files(run_log, report_log)

  logger.info 'Benchmark finished'
end
