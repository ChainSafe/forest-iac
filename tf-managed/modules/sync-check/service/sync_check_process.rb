# frozen_string_literal: true

require_relative 'ruby_common/slack_client'
require_relative 'ruby_common/utils'

require 'English'
require 'fileutils'
require 'sys/filesystem'
require 'logger'
require 'open3'

SLACK_TOKEN = get_and_assert_env_variable 'FOREST_SLACK_API_TOKEN'
CHANNEL = get_and_assert_env_variable 'FOREST_SLACK_NOTIF_CHANNEL'
FOREST_DATA = get_and_assert_env_variable 'FOREST_TARGET_DATA'
FOREST_SCRIPTS = get_and_assert_env_variable 'FOREST_TARGET_SCRIPTS'
FOREST_TAG = get_and_assert_env_variable 'FOREST_TAG'

# Sync check class encompassing all required methods and fields
class SyncCheck
  def initialize(slack_client = nil)
    @logger = Logger.new($stdout)
    @client = slack_client || SlackClient.new(CHANNEL, SLACK_TOKEN)
  end

  # Runs a command with an arbitrary binary available in the chainsafe/forest image
  def run_forest_container(binary, command)
    @logger.debug "Running `#{binary}` command with #{command}"
    stdout, stderr, status = Open3.capture3("docker run --entrypoint #{binary} \
                --init \
                --volume forest-data:#{FOREST_DATA} \
                --volume sync-check:#{FOREST_SCRIPTS} \
                --rm \
                ghcr.io/chainsafe/forest:#{FOREST_TAG} \
                --config #{FOREST_SCRIPTS}/sync_check.toml \
                #{command}")
    raise "Failed `#{binary} #{command}`.\n```\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}```" unless status.success?
  end

  # Runs a command for forest-tool. The configuration is pre-defined.
  def run_forest_tool(command)
    run_forest_container('forest-tool', command)
  end

  # Runs a command for forest node. The configuration is pre-defined.
  def run_forest(command)
    run_forest_container('forest', command)
  end

  # Gets current disk usage.
  def disk_usage
    stat = Sys::Filesystem.stat('/')
    1 - stat.blocks_available.fdiv(stat.blocks)
  end

  # Starts docker compose services.
  def start_services
    @logger.info 'Starting services'
    `docker compose up --build --force-recreate --detach`
    raise 'Failed to start services' unless $CHILD_STATUS.success?
  end

  # Stops docker compose services
  def stop_services
    @logger.info 'Stopping services'
    `docker compose down`
    raise 'Failed to stop services' unless $CHILD_STATUS.success?
  end

  # Checks if the docker compose services are up
  def services_up?
    output = `docker compose ps --services --filter "status=running"`
    $CHILD_STATUS.success? && !output.strip.empty?
  end

  # logs and sends a slack message containing the error description
  def report_error(error)
    @logger.error error.message
    @client.post_message '💀 Sync check fiasco ❌'
    @client.attach_comment error.message
  end

  # Cleans up the sync check
  def cleanup
    @logger.info 'Cleaning up sync check'
    @client.post_message '🧹 Cleaning up sync check'

    stop_services
    cleanup_command = "docker run --rm --volume forest-data:#{FOREST_DATA} busybox sh -c 'rm -rf #{FOREST_DATA}/**'"

    stdout, stderr, status = Open3.capture3(cleanup_command)
    if status.success?
      @logger.info 'Cleanup successful'
      @client.attach_comment '🧹 Docker volume cleanup completed successfully ✅'
    else
      error_message = "Cleanup failed with status: #{status.exitstatus}. STDOUT: #{stdout}, STDERR: #{stderr}"
      @logger.error error_message
      @client.attach_comment "Cleanup error: #{error_message}"
      raise 'Failed to clean up Docker volume'
    end

    @client.attach_comment '🧹 Cleanup finished ✅'
  end

  # start the sync check loop
  def run
    loop do
      begin
        `docker image prune -f`
        cleanup unless disk_usage < 0.95
        start_services unless services_up?
      rescue StandardError => e
        report_error e
      end

      # sleep 1 hour before checking again
      sleep 60 * 60
    end
  end
end

#####
# Runs only when executed directly
SyncCheck.new.run if __FILE__ == $PROGRAM_NAME
