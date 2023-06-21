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

# Current datetime, to append to the log files
DATE = Time.new.strftime '%FT%H:%M:%S'
LOG_HEALTH = "#{LOG_DIR}/benchmark_#{DATE}_health"
LOG = "#{LOG_DIR}/benchmark_#{DATE}_forest"
LOG_SYNC = "#{LOG_DIR}/benchmark_#{DATE}_sync"

# Create log directory
FileUtils.mkdir_p LOG_DIR

logger = Logger.new(LOG_SYNC)

health_check_passed = false

# Execute the shell commands
init_commands = <<-CMD
  dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && \
  dnf install -y dnf-plugins-core docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose gcc make aria2 zstd clang clang-devel cmake && \
  dnf install -y git bzr jq pkgconfig mesa-libOpenCL mesa-libOpenCL-devel opencl-headers ocl-icd ocl-icd-devel llvm wget hwloc hwloc-devel golang rust cargo s3cmd
  dnf clean all
  gem install slack-ruby-client sys-filesystem bundler concurrent-ruby deep_merge tomlrb toml-rb csv fileutils logger open3 optparse set tmpdir
CMD

# Init and Run benchmark
logger.info 'Initializing...'
init_status = system(init_commands)

if init_status
  logger.info 'Running the benchmark...'
  health_check_passed = system("bash #{SCRIPTS_DIR}/run_benchmark.sh > #{LOG_HEALTH} 2>&1")
  logger.info 'Benchmark run completed'

# Save the log capture from the Forest container
container_logs = DockerUtils.get_container_logs hostname
File.write(LOG_FOREST, container_logs)

client = SlackClient.new CHANNEL, SLACK_TOKEN

if init_status && health_check_passed
  client.post_message "✅ Benchmark run was successful. 🌲🌳🌲🌳🌲"
else
  client.post_message "⛔ Benchmark run fiascoed. 🔥🌲🔥 "
end
client.attach_files(LOG_HEALTH, LOG_SYNC, LOG_FOREST)

logger.info 'Benchmark finished'
