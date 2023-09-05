# frozen_string_literal: true

require 'active_support/time'

# Filecoin snapshot class
# - network: mainnet, calibnet
# - date: date when the snapshot was taken
# - height: height of the snapshot (epochs)
# - file_name: name of the file
# - url_s3: url of the snapshot on S3
# - url: url of the snapshot on the web
class Snapshot
  attr_accessor :network, :date, :height, :file_name, :url_s3, :url

  def initialize(params)
    check_for_nil_params(params)
    check_network_param(params)

    @network = params[:network].downcase
    @date = params[:date].to_date
    @height = params[:height].to_i
    @file_name = params[:file_name]
    @url_s3 = params[:url_s3]
    @url = params[:url]
  end

  def check_for_nil_params(params)
    return unless params[:network].nil? || params[:date].nil? || params[:height].nil? || \
                  params[:file_name].nil? || params[:url_s3].nil? || params[:url].nil?

    raise ArgumentError,
          'Missing argument'
  end

  def check_network_param(params)
    return unless params[:network].downcase != 'mainnet' && params[:network].downcase != 'calibnet'

    raise ArgumentError,
          "Invalid network: #{params[:network]}"
  end

  def to_s
    "#{@network}/#{@height}/#{@url}"
  end

  # Deletes the snapshot from S3 - the full snapshot,
  # the checksum and the compressed version.
  def delete
    system("s3cmd del #{@url_s3}")
    checksum = Pathname.new(@url_s3).sub_ext('.sha256sum')
    system("s3cmd del #{checksum}")
    compressed = Pathname.new(@url_s3).sub_ext('.car.zst')
    system("s3cmd del #{compressed}")
  end
end

# Define the line format to use in the file matching step and get the output of the `s3cmd ls` command
def prepare_to_list_snapshots(chain_name, bucket)
  ls_format = %r{\d{4}-\d{2}-\d{2} \d{2}:\d{2}\s*\d*\s*s3://#{bucket}/#{chain_name}/(.+)}

  output = `s3cmd ls s3://#{bucket}/#{chain_name}/`

  [ls_format, output]
end

# Define the snapshot format to use in the file matching step and create an empty snapshot list
def prepare_to_update_snapshot_list
  snapshot_format = \
    /^(?:[^_]+?)_snapshot_(?<network>[^_]+?)_(?<date>\d{4}-\d{2}-\d{2})_height_(?<height>\d+)(?:\.forest)?\.car.zst$/
  snapshot_list = []
  [snapshot_format, snapshot_list]
end

# Populates the `params` Hash with the values obtained from the file matching step
def match_assignments(bucket, chain_name, endpoint, file, match)
  params = {}
  params[:network] = match[:network]
  params[:date] = match[:date]
  params[:height] = match[:height]
  params[:file_name] = file
  params[:url_s3] = "s3://#{bucket}/#{chain_name}/#{file}"
  params[:url] = "https://#{bucket}.#{endpoint}/#{chain_name}/#{file}"
  params
end

# Update the snapshot list with the snapshots found in the S3 space hosted by Forest
def update_snapshot_list(ls_format, output, bucket, chain_name, endpoint)
  (snapshot_format, snapshot_list) = prepare_to_update_snapshot_list
  output.each_line do |line|
    line.match(ls_format) do |l|
      file = l.captures[0]
      file.match(snapshot_format) do |match|
        params = match_assignments(bucket, chain_name, endpoint, file, match)
        snapshot_list << Snapshot.new(params)
      end
    end
  end
  snapshot_list
end

# List the snapshots available in the S3 space hosted by Forest
def list_snapshots(chain_name = 'calibnet', bucket = 'forest-snapshots', endpoint = 'fra1.digitaloceanspaces.com')
  (ls_format, output) = prepare_to_list_snapshots(chain_name, bucket)

  snapshot_list = update_snapshot_list(ls_format, output, bucket, chain_name, endpoint)

  # Sort the snapshots by decreasing height
  snapshot_list.sort_by { |a| -a.height }
end
