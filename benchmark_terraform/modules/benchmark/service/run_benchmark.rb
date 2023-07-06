# frozen_string_literal: true

require_relative 'ruby_common/slack_client'
require_relative 'ruby_common/utils'

require 'logger'
require 'fileutils'

# Retrieves an environmental variable, failing if its not set or empty.
def get_and_assert_env_variable(name)
  var = ENV[name]
  raise "Please set #{name} environmental variable" if var.nil? || var.empty?

  var
end

SLACK_TOKEN = get_and_assert_env_variable 'SLACK_API_TOKEN'
CHANNEL = get_and_assert_env_variable 'SLACK_NOTIF_CHANNEL'
SCRIPTS_DIR = get_and_assert_env_variable 'BASE_FOLDER'
LOG_DIR = get_and_assert_env_variable 'BASE_FOLDER'

loop do
  # Current datetime, to append to the log files
  DATE = Time.new.strftime '%FT%H:%M:%S'
  LOG_HEALTH = "#{LOG_DIR}/benchmark_#{DATE}_health"
  LOG_SYNC = "#{LOG_DIR}/benchmark_#{DATE}_sync"
  
  # Create log directory
  FileUtils.mkdir_p LOG_DIR
  
  logger = Logger.new(LOG_SYNC)
  
  logger.info 'Running the benchmark...'
  health_check_passed = system("bash #{SCRIPTS_DIR}/run_benchmark.sh > #{LOG_HEALTH} 2>&1")
  logger.info 'Benchmark run completed'
  
  client = SlackClient.new CHANNEL, SLACK_TOKEN
  
  if health_check_passed
    client.post_message "✅ Benchmark run was successful. 🌲🌳🌲🌳🌲"
  else
    client.post_message "⛔ Benchmark run fiascoed. 🔥🌲🔥 "
  end
  client.attach_files(LOG_HEALTH, LOG_SYNC)
  
  logger.info 'Benchmark finished'
end
