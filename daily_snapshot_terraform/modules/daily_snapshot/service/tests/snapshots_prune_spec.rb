# frozen_string_literal: true

require_relative '../snapshots_prune'
require 'rspec'

describe 'prune_snapshots' do
  describe 'when there are no snapshots' do
    it 'returns an empty array' do
      expect(prune_snapshots([])).to eq([])
    end
  end

  describe 'when there is one snapshot' do
    let(:snapshot) { double(delete: nil, date: '2023-06-27') }
    it 'it is not deleted' do
      expect(prune_snapshots([snapshot])).to eq([])
      expect(snapshot).not_to have_received(:delete)
    end
  end

  describe 'when are multiple snapshots for a single day' do
    # Buffer of two recent snapshots
    let(:snapshot1) { double(delete: nil, date: '2023-06-27') }
    # Last snapshot of the day
    let(:snapshot2) { double(delete: nil, date: '2023-06-27') }
    # Snapshot to be deleted
    let(:snapshot3) { double(delete: nil, date: '2023-06-27') }

    it 'deletes all but the first two (assumes snapshots are provided in descending height order)' do
      pruned_snapshots = prune_snapshots([snapshot1, snapshot2, snapshot3])

      expect(pruned_snapshots).to eq([snapshot3])
      expect(snapshot1).not_to have_received(:delete)
      expect(snapshot2).not_to have_received(:delete)
      expect(snapshot3).to have_received(:delete)
    end
  end

  describe 'when there are multiple snapshots for the past week' do
    # snapshot from Tuesday
    let(:snapshot1) { double(delete: nil, date: '2023-06-27') }
    # snapshot from Monday
    let(:snapshot2) { double(delete: nil, date: '2023-06-26') }
    # snapshot from Sunday
    let(:snapshot3) { double(delete: nil, date: '2023-06-25') }
    # snapshot from last Tuesday
    let(:snapshot4) { double(delete: nil, date: '2023-06-20') }

    it 'does not delete anything' do
      pruned_snapshots = prune_snapshots([snapshot1, snapshot2, snapshot3, snapshot4])

      expect(pruned_snapshots).to eq([])
      [snapshot1, snapshot2, snapshot3].each do |snapshot|
        expect(snapshot).not_to have_received(:delete)
      end
    end
  end

  describe 'when there are multiple snapshot over more one year' do
    current_date = Date.parse('2023-06-27')
    days_in_test = 365

    let :snapshots do
      (1..days_in_test).map do |i|
        snapshot_date = current_date - i
        double(date: snapshot_date, delete: nil)
      end
    end

    it 'deletes all but the first one of each week' do
      snapshots_count = snapshots.length
      pruned_snapshots = prune_snapshots(snapshots)

      weeks_in_test = days_in_test / 7
      # Should keep 1 buffer + 7 snapshots in in the first week + 1 snapshot per week afterwards
      expected_snapshots_keep_count = 1 + 7 + weeks_in_test
      expect(pruned_snapshots.length).to eq(snapshots_count - expected_snapshots_keep_count)

      snapshots.take(9).each do |snapshot|
        expect(snapshot).not_to have_received(:delete)
      end

      # First 9 snapshots should not be deleted
      # afterwards, only Sunday snapshots should be kept
      # Year boundary will be kept as well.
      snapshots.each_with_index do |snapshot, i|
        if i < 9 || snapshot.date.sunday? || snapshot.date == Date.parse('2022-12-31')
          expect(snapshot).not_to have_received(:delete)
        else
          expect(snapshot).to have_received(:delete)
        end
      end
    end
  end
end
