# frozen_string_literal: true

require_relative '../snapshots_prune'
require 'rspec'

DAILY_SNAPSHOTS = 1

# Creates a list of snapshots for the same day.
# Returns an array of doubles.
def create_same_day_snapshots(date, count)
  (1..count).map do
    double(date: date, delete: nil)
  end
end

# Creates a list of snapshots for consecutive days. The snapshots are in descending order.
# Returns an array of doubles.
def create_consecutive_days_snapshots(start_date, count)
  (0...count).map do |i|
    date = start_date - i
    double(date: date, delete: nil)
  end
end

# Helper function for `prune_snapshots`
def no_snapshots
  describe 'when there are no snapshots' do
    it 'returns an empty array' do
      expect(prune_snapshots([])).to eq([])
    end
  end
end

# Helper function for `prune_snapshots`
def one_snapshot
  describe 'when there is one snapshot' do
    let(:snapshot) { create_same_day_snapshots(Date.parse('2023-06-27'), 1).first }
    it 'it is not deleted' do
      expect(prune_snapshots([snapshot])).to eq([])
      expect(snapshot).not_to have_received(:delete)
    end
  end
end

# Helper function for `delete_all_but_first_two`
def one_day_pruning(snapshots)
  snapshots.each_with_index do |snapshot, index|
    if index < BUFFER_SIZE + DAILY_SNAPSHOTS
      expect(snapshot).not_to have_received(:delete)
    else
      expect(snapshot).to have_received(:delete)
    end
  end
end

# Helper function for `multiple_snapshots_one_day`
def delete_all_but_first_two(snapshots)
  it 'deletes all but the first two (assumes snapshots are provided in descending height order)' do
    pruned_snapshots = prune_snapshots(snapshots)
    expect(pruned_snapshots.length).to eq(snapshots.length - BUFFER_SIZE - DAILY_SNAPSHOTS)

    one_day_pruning(snapshots)
  end
end

# Helper function for `prune_snapshots`
def multiple_snapshots_one_day
  describe 'when are multiple snapshots for a single day' do
    snapshot_count = BUFFER_SIZE + 42
    let :snapshots do
      create_same_day_snapshots(Date.parse('2023-06-27'), snapshot_count)
      delete_all_but_first_two(snapshots)
    end
  end
end

# Helper function for `delete_all_but_first_of_each_week`
def snapshot_preprocessing(snapshots, days_in_test)
  snapshots_count = snapshots.length
  pruned_snapshots = prune_snapshots(snapshots)

  weeks_in_test = days_in_test / 7
  # Should keep daily + 10 (buffer) + 7 snapshots in in the first week
  expected_snapshots_keep_count = BUFFER_SIZE + 7 + weeks_in_test
  expect(pruned_snapshots.length).to eq(snapshots_count - expected_snapshots_keep_count)
end

# Helper function for `delete_all_but_first_of_each_week`
def one_year_pruning(snapshots)
  # First 18 snapshots should not be deleted (day + buffer + week)
  # afterwards, only Sunday snapshots should be kept
  # Year boundary will be kept as well.
  snapshots.drop(18).each do |snapshot|
    if snapshot.date.sunday? || snapshot.date == Date.parse('2022-12-31')
      expect(snapshot).not_to have_received(:delete)
    else
      expect(snapshot).to have_received(:delete)
    end
  end
end

# Helper function for `multiple_snapshots_one_year`
def delete_all_but_first_of_each_week(snapshots, days_in_test)
  it 'deletes all but the first one of each week' do
    snapshot_preprocessing(snapshots, days_in_test)

    snapshots.take(18).each do |snapshot|
      expect(snapshot).not_to have_received(:delete)
    end

    one_year_pruning(snapshots)
  end
end

# Helper function for `multiple_snapshots_one_year`
def multiple_snapshots_one_year_assignments
  current_date = Date.parse('2023-06-27')
  days_in_test = 366
  first_day_snapshots = 9
  [current_date, days_in_test, first_day_snapshots]
end

# Helper function for `prune_snapshots`
def multiple_snapshots_one_year
  describe 'when there are multiple snapshot over one year' do
    current_date, days_in_test, first_day_snapshots = multiple_snapshots_one_year_assignments

    let :snapshots do
      same_day = create_same_day_snapshots(current_date, first_day_snapshots)
      rest = create_consecutive_days_snapshots(current_date, days_in_test - first_day_snapshots)

      delete_all_but_first_of_each_week((same_day + rest), days_in_test)
    end
  end
end

describe 'prune_snapshots' do
  no_snapshots

  one_snapshot

  multiple_snapshots_one_day

  multiple_snapshots_one_year
end
