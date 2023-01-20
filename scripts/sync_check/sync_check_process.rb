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
  def initialize
    @logger = Logger.new($stdout)
    @client = SlackClient.new CHANNEL, SLACK_TOKEN
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

  # Runs a command for forest-cli. The configuration is pre-defined.
  def run_forest_cli(command)
    run_forest_container('forest-cli', command)
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

  # Downloads snapshots from trusted sources.
  def download_snapshots
    @logger.info 'Downloading snapshots'
    run_forest_cli '--chain calibnet snapshot fetch'
    run_forest_cli '--chain mainnet snapshot fetch'
  end

  # Retrieves path to the relevant snapshot based on the network chosen.
  def snapshot_path(network)
    Dir.glob("#{FOREST_DATA}/snapshots/#{network}/*.car")[0] or raise "Can't find snapshot in #{dir}"
  end

  # Imports the snapshots
  def import_snapshots
    @logger.info 'Importing snapshots'
    run_forest "--chain calibnet --halt-after-import --import-snapshot #{snapshot_path('calibnet')}"
    run_forest "--chain mainnet --halt-after-import --import-snapshot #{snapshot_path('mainnet')}"
  end

  # Deletes all snapshots to free up memory.
  def delete_snapshots
    @logger.info 'Deleting snapshots'
    run_forest_cli '--chain calibnet snapshot clean --force'
    run_forest_cli '--chain mainnet snapshot clean --force'
  end

  # Starts docker-compose services. It first downloads and imports the snapshots.
  def start_services
    @logger.info 'Starting services'
    download_snapshots
    import_snapshots
    delete_snapshots

    `docker-compose up --build --force-recreate --detach`
    raise 'Failed to start services' unless $CHILD_STATUS.success?
  end

  # Stops docker-compose services
  def stop_services
    @logger.info 'Stopping services'
    `docker-compose down`
    raise 'Failed to stop services' unless $CHILD_STATUS.success?
  end

  # Checks if the docker-compose services are up
  def services_up?
    output = `docker-compose ps --services --filter "status=running"`
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
    FileUtils.rm_rf(Dir.glob("#{FOREST_DATA}/**"))

    @client.attach_comment '🧹 Cleanup finished ✅'
  end

  # start the sync check loop
  def run
    loop do
      begin
        cleanup unless disk_usage < 0.8
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
SyncCheck.new.run
