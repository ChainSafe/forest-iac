# frozen_string_literal: true

require_relative 'list_snapshots'

require 'date'
require 'pathname'

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
    super entry.date.strftime('%m%y')
  end
end

# Represents Months Bucket. The key is "MMYY"
class MonthsBucket < SnapshotBucket
  def add?(entry)
    super entry.date.strftime('%m%y')
  end
end

# Prunes snapshots directory with the following retention policy:
# * keep at most 1 snapshot per day
# * keep all snapshots generated in the last 7 days,
# * keep one snapshot per week for the last 4 weeks,
# * keep one snapshot per month after 4 weeks.
#
# Returns pruned snapshots' filenames.
def prune_snapshots(snapshots)
  day_unique_bucket = DayBucket.new
  day_bucket = DayBucket.new 7
  weeks_bucket = WeeksBucket.new 4
  months_bucket = MonthsBucket.new
  buckets = [day_bucket, weeks_bucket, months_bucket]

  # iterate over each entry and try to add it to the buckets, newest first.
  snapshots
    # ignore the first snapshot to keep a buffer of two recent snapshots.
    # this makes it less likely that we delete a snapshot that is being downloaded.
    .drop(1)
    # keep snapshots (ie reject) if they fit in a bucket while also having a unique date
    .reject  { |f| day_unique_bucket.add? f and buckets.any? { |bucket| bucket.add? f } }
    # delete all snapshots that weren't rejected or dropped
    .each    { |f| f.delete }
end
