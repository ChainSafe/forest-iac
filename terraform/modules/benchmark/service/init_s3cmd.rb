require 'open3'

def run_s3cmd(*args)
  Open3.popen3('s3cmd', *args) do |stdin, stdout, stderr, wait_thr|
    exit_status = wait_thr.value.exitstatus
    output = stdout.read
    error_message = stderr.read
    [exit_status, output, error_message]
  end
end

config_file = "#{Dir.home}/.s3cfg"

# Check if the configuration file already exists
if File.exist?(config_file)
  puts 's3cmd is already configured. Skipping initialization.'
else
  config_command = [
    '--dump-config',
    "--host=#{ENV['BENCHMARK_ENDPOINT']}",
    "--host-bucket=%(bucket)s.#{ENV['BENCHMARK_ENDPOINT']}",
    "--access_key=#{ENV['AWS_ACCESS_KEY_ID']}",
    "--secret_key=#{ENV['AWS_SECRET_ACCESS_KEY']}",
    '--multipart-chunk-size-mb=4096'
  ]

  config_status, config_output, config_error = run_s3cmd(*config_command)
  if config_status.zero?
    File.write(config_file, config_output)
    puts 's3cmd configuration completed successfully.'
  else
    puts "Error configuring s3cmd: #{config_error}"
    exit 1
  end
end
