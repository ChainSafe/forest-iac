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

describe 'prune_snapshots' do
  describe 'when there are no snapshots' do
    it 'returns an empty array' do
      expect(prune_snapshots([])).to eq([])
    end
  end

  describe 'when there is one snapshot' do
    let(:snapshot) { create_same_day_snapshots(Date.parse('2023-06-27'), 1).first }
    it 'it is not deleted' do
      expect(prune_snapshots([snapshot])).to eq([])
      expect(snapshot).not_to have_received(:delete)
    end
  end

  describe 'when are multiple snapshots for a single day' do
    snapshot_count = BUFFER_SIZE + 42
    let :snapshots do
      create_same_day_snapshots(Date.parse('2023-06-27'), snapshot_count)
    end

    it 'deletes all but the first two (assumes snapshots are provided in descending height order)' do
      pruned_snapshots = prune_snapshots(snapshots)
      expect(pruned_snapshots.length).to eq(snapshots.length - BUFFER_SIZE - DAILY_SNAPSHOTS)

      snapshots.each_with_index do |snapshot, index|
        if index < BUFFER_SIZE + DAILY_SNAPSHOTS
          expect(snapshot).not_to have_received(:delete)
        else
          expect(snapshot).to have_received(:delete)
        end
      end
    end
  end

  describe 'when there are multiple snapshot over more one year' do
    current_date = Date.parse('2023-06-27')
    days_in_test = 366
    first_day_snapshots = 9

    let :snapshots do
      same_day = create_same_day_snapshots(current_date, first_day_snapshots)
      rest = create_consecutive_days_snapshots(current_date, days_in_test - first_day_snapshots)
      same_day + rest
    end

    it 'deletes all but the first one of each week' do
      snapshots_count = snapshots.length
      pruned_snapshots = prune_snapshots(snapshots)

      weeks_in_test = days_in_test / 7
      # Should keep daily + 10 (buffer) + 7 snapshots in in the first week
      expected_snapshots_keep_count = BUFFER_SIZE + 7 + weeks_in_test
      expect(pruned_snapshots.length).to eq(snapshots_count - expected_snapshots_keep_count)

      snapshots.take(18).each do |snapshot|
        expect(snapshot).not_to have_received(:delete)
      end

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
  end
end
