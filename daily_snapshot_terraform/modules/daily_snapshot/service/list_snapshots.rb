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

  def initialize(network, date, height, file_name, url_s3, url)
    if network.nil? || date.nil? || height.nil? || file_name.nil? || url_s3.nil? || url.nil?
      raise ArgumentError, 'Missing argument'
    end

    network = network.downcase

    if network != 'mainnet' && network != 'calibnet'
      raise ArgumentError, 'Invalid network'
    end

    @network = network
    @date = date.to_date
    @height = height.to_i
    @file_name = file_name
    @url_s3 = url_s3
    @url = url
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

# List the snapshots available in the S3 space hosted by Forest
def list_snapshots(chain_name = 'calibnet', bucket = 'forest-snapshots', endpoint = 'fra1.digitaloceanspaces.com')
  ls_format = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}\s*\d*\s*s3:\/\/#{bucket}\/#{chain_name}\/(.+)/
  snapshot_format = /^([^_]+?)_snapshot_(?<network>[^_]+?)_(?<date>\d{4}-\d{2}-\d{2})_height_(?<height>\d+)\.car$/

  output = `s3cmd ls s3://#{bucket}/#{chain_name}/`

  snapshot_list = []

  output.each_line do |line|
    line.match(ls_format) do |m|
      file = m.captures[0]
      file.match(snapshot_format) do |m|
        url = "https://#{bucket}.#{endpoint}/#{chain_name}/#{file}"
        url_s3 = "s3://#{bucket}/#{chain_name}/#{file}"
        snapshot = Snapshot.new m[:network], m[:date], m[:height], file, url_s3, url
        snapshot_list << snapshot
      end
    end
  end
  # Sort the snapshots by decreasing height
  snapshot_list.sort_by { |a| -a.height }
end
