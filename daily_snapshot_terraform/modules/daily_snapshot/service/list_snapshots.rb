# frozen_string_literal: true
require 'active_support/time'

Snapshot = Struct.new(:network, :date, :height, :file_name, :url_s3, :url) do
  def delete
    system("s3cmd del #{url_s3}")
    checksum = Pathname.new(url_s3).sub_ext('.sha256sum')
    system("s3cmd del #{checksum}")
    compressed = Pathname.new(url_s3).sub_ext('.car.zst')
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
    line.match(ls_format) { |m|
      file = m.captures[0]
      file.match(snapshot_format) { |m| 
        url = "https://#{bucket}.#{endpoint}/#{chain_name}/#{file}"
        url_s3 = "s3://#{bucket}/#{chain_name}/#{file}"
        snapshot = Snapshot.new m[:network], m[:date].to_date, m[:height].to_i, file, url_s3, url
        snapshot_list << snapshot
      }
    }
  end
  # Sort the snapshots by decreasing height
  snapshot_list.sort_by { |a| -a.height }
end
