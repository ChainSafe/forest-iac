# frozen_string_literal: true

require_relative 'list_snapshots'

require 'date'
require 'pathname'

BUFFER_SIZE = 10

# Class representing a snapshot bucket with a defined number of entries.
class SnapshotBucket
  def initialize(max_entries = nil)
    @max_entries = max_entries
    @entries = Set.new
  end

  # Adds an entry to the bucket unless it is already full or already contains the key.
  # Return false on insert failure.
  def add?(entry)
    return false if !@max_entries.nil? && @entries.size >= @max_entries

    !@entries.add?(entry).nil?
  end
end

# Represents Day Bucket. They key is the date.
class DayBucket < SnapshotBucket
  def add?(entry)
    super entry.date
  end
end

# Represents Weeks Bucket. The key is "WWYY" (week starts on Monday).
class WeeksBucket < SnapshotBucket
  def add?(entry)
    super entry.date.strftime('%W%y')
  end
end

# Prunes snapshots directory with the following retention policy:
# * keep at most 2 snapshots per day
# * keep all snapshots generated in the last 7 days,
# * keep one snapshot per week afterwards.
#
# Returns pruned snapshots' filenames.
def prune_snapshots(snapshots)
  day_unique_bucket = DayBucket.new
  day_bucket = DayBucket.new 7
  weeks_bucket = WeeksBucket.new
  buckets = [day_bucket, weeks_bucket]

  # iterate over each entry and try to add it to the buckets, newest first.
  snapshots
    # Ignore the first 10 snapshots to keep a solid buffer.
    # This makes it less likely that we delete a snapshot that is being downloaded.
    # It also helps with the CDN cache not propagating fast enough.
    .drop(BUFFER_SIZE)
    # keep snapshots (ie reject) if they fit in a bucket while also having a unique date
    .reject { |f| day_unique_bucket.add? f and buckets.any? { |bucket| bucket.add? f } }
    # delete all snapshots that weren't rejected or dropped
    .each(&:delete)
end
