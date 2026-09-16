#!/usr/bin/env ruby
# frozen_string_literal: true

# Verifies Filecoin JSON-RPC answers against the https://chain.data.riba.plus
# dataset. Exit codes: 0 all pass, 1 any mismatch, 2 no mismatch but an archive
# day is not published yet (partial coverage).
#
# --probe only checks that the dataset has published every archive day the
# range needs (0 yes, 2 no, 1 dataset unreachable), without touching a node.
#
# Methods (--only, default all):
#   blocks   - eth_getBlockByNumber + eth_getTransactionByBlockNumberAndIndex
#   receipts - eth_getBlockReceipts
#   tipsets  - Filecoin.ChainGetTipSetByHeight
#   logs     - eth_getLogs (reference derived from the receipts archive)

require 'json'
require 'net/http'
require 'open-uri'
require 'optparse'
require 'brotli'

SECONDS_IN_EPOCH = 30
SECONDS_IN_DAY = 24 * 60 * 60
EPOCHS_IN_DAY = SECONDS_IN_DAY / SECONDS_IN_EPOCH
DIFF_LIMIT = 20
DIFF_LINE_LIMIT = 512
NET_ERRORS = [IOError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout].freeze
DATASET_URL = 'https://chain.data.riba.plus/fil'

# Filecoin.StateNetworkName -> dataset path segment.
NETWORKS = { 'mainnet' => 'mainnet', 'calibrationnet' => 'calibnet' }.freeze
# Dataset path segment -> genesis timestamp, for --probe --network (no node).
GENESIS = { 'mainnet' => 1_598_306_400, 'calibnet' => 1_667_326_380 }.freeze

# Method -> daily archive file. logs has no archive; it derives from receipts.
ARCHIVE_FILES = {
  'blocks' => 'eth_getBlockByNumber',
  'receipts' => 'eth_getBlockReceipts',
  'tipsets' => 'Filecoin.ChainGetTipSetByHeight',
  'logs' => 'eth_getBlockReceipts'
}.freeze

def hex(num) = format('0x%x', num)

# Forest omits accessList on legacy (type 0x0) txs where the dataset emits []
# (#7205); dropped until fixed.
def norm_tx(txn) = txn.is_a?(Hash) ? txn.except('accessList') : txn

def norm_txs(txs) = txs.map { norm_tx(it) }

def norm_block(block)
  return block unless block.is_a?(Hash)

  block.dup.tap do |b|
    b['transactions'] = norm_txs(b['transactions']) if b['transactions'].is_a?(Array)
  end
end

def error_message(resp) = resp.dig('error', 'message')

def null_round_error?(resp) = resp['result'].nil? && error_message(resp).to_s.include?('null round')

def expected_logs(entry) = (entry['result'] || []).flat_map { it['logs'] || [] }

# Differing paths between two JSON documents; key order never matters.
def deep_diff(node, archive, path = '$')
  return [] if node == archive

  case [node, archive]
  in [Hash => a, Hash => b]
    (a.keys | b.keys).flat_map { deep_diff(a[it], b[it], "#{path}.#{it}") }
  in [Array => a, Array => b]
    diff_arrays(a, b, path)
  else
    ["#{path}: node=#{excerpt(node)} archive=#{excerpt(archive)}"]
  end
end

def excerpt(value, limit = DIFF_LINE_LIMIT / 4)
  json = value.to_json
  json.size > limit ? "#{json[0, limit]}… (#{json.size} chars)" : json
end

def diff_arrays(node, archive, path)
  header = []
  header << "#{path}: array sizes differ (node=#{node.size}, archive=#{archive.size})" if node.size != archive.size
  header + node.take(archive.size).each_with_index.flat_map { |x, i| deep_diff(x, archive[i], "#{path}[#{i}]") }
end

# Daily files split at midnight UTC: an epoch's day is its UTC date and its line
# is 1 + its offset from that day's first epoch (genesis % 30 == 0 on both networks).
def locate(epoch, genesis)
  ts = (epoch * SECONDS_IN_EPOCH) + genesis
  [Time.at(ts, in: 'UTC').strftime('%Y/%m/%d'), 1 + (ts % SECONDS_IN_DAY / SECONDS_IN_EPOCH)]
end

# JSON-RPC over a persistent connection; reconnects once if the server closed it.
class Rpc
  def initialize(url)
    @uri = URI(url.include?('://') ? url : "http://#{url}")
  end

  def call(method, params)
    request = Net::HTTP::Post.new(@uri.request_uri, 'Content-Type' => 'application/json')
    request.body = { jsonrpc: '2.0', id: 1, method:, params: }.to_json
    perform(request)
  rescue *NET_ERRORS
    @http = nil
    perform(request)
  end

  private

  def perform(request) = JSON.parse(http.request(request).body)

  def http
    @http ||= Net::HTTP.start(@uri.host, @uri.port, use_ssl: @uri.scheme == 'https')
  end
end

# Daily archive files, downloaded once per run and shared across method threads.
class Archive
  def initialize(net, base: ENV.fetch('DATASET_URL', DATASET_URL))
    @net = net
    @base = base
    @cache = {}
    @mutex = Mutex.new
  end

  # Lines of the day's ndjson, or nil if the day isn't published. One in-flight
  # fetch per (file, date); the lock only guards the insert.
  def daily(file, date)
    @mutex.synchronize { @cache[[file, date]] ||= Thread.new { fetch(file, date) } }.value
  end

  # 200 is published, 404 is not. Anything else after retries raises, so an
  # outage never passes for a missing day.
  def published?(file, date, attempts: 3)
    uri = url(file, date)
    last = nil
    attempts.times do |i|
      sleep i
      last = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') { it.head(uri.request_uri) }
      return true if last.is_a?(Net::HTTPSuccess)
      return false if last.is_a?(Net::HTTPNotFound)
    rescue *NET_ERRORS => e
      last = e
    end
    raise "#{uri}: #{last.is_a?(Exception) ? last.message : "HTTP #{last.code}"} after #{attempts} attempts"
  end

  private

  def url(file, date) = URI("#{@base}/#{@net}/daily/#{date}/#{file}.v1.r1.ndjson.brotli")

  def fetch(file, date, attempts: 3)
    uri = url(file, date)
    attempts.times do |i|
      return download(uri).lines
    rescue OpenURI::HTTPError => e
      return nil if e.io.status.first == '404'

      sleep 1 + i
    rescue *NET_ERRORS
      sleep 1 + i
    end
    nil
  end

  # The server only sends brotli bytes to clients that ask for them.
  def download(uri)
    uri.open('Accept-Encoding' => 'br') do |f|
      f.content_encoding.include?('br') ? Brotli.inflate(f.read) : f.read
    end
  end
end

# One verification method over an epoch range, diffing every archive entry
# against the node.
class Checker
  METHODS = ARCHIVE_FILES.keys.freeze

  attr_reader :out

  def initialize(method:, range:, rpc_url:, archive:, genesis:)
    @method = method
    @range = range
    @archive = archive
    @genesis = genesis
    @rpc = Rpc.new(rpc_url)
    @out = []
    @failed = false
  end

  # :pass / :fail (mismatch) / :no_data (archive day unavailable).
  def run
    epoch = @range.begin
    epoch = check_day(epoch) while epoch && epoch <= @range.end
    return :fail if @failed

    epoch ? :pass : :no_data
  end

  private

  # Checks from `epoch` to the end of its UTC day (or of the range); returns the
  # next epoch, or nil if the archive day ran out.
  def check_day(epoch)
    date, line = locate(epoch, @genesis)
    day_end = [epoch + EPOCHS_IN_DAY - line, @range.end].min
    @out << "--- #{@method}: epochs #{epoch}..#{day_end} (#{date}, #{ARCHIVE_FILES[@method]}) ---"
    (epoch..day_end).zip(day_entries(date, line)) do |e, raw|
      # The archive publishes chronologically, so every later epoch is missing too.
      if raw.to_s.strip.empty?
        @out << "no archive for #{date} (day not published?); stopping #{@method} at epoch #{e}."
        return nil
      end
      send("check_#{@method}", e, JSON.parse(raw))
    end
    day_end + 1
  end

  def day_entries(date, line) = @archive.daily(ARCHIVE_FILES[@method], date)&.drop(line - 1) || []

  # Null rounds: blocks/receipts must answer with the "null round" error (any
  # other response is a discrepancy); logs must return []; tipsets walks back to
  # the nearest lower tipset, so it agrees iff Height < epoch.

  def check_blocks(epoch, entry)
    resp = @rpc.call('eth_getBlockByNumber', [hex(epoch), true])
    return null_round(epoch, resp, agreed: null_round_error?(resp), number: resp.dig('result', 'number')) if entry.nil?

    compare(label(epoch), norm_block(resp['result']), norm_block(entry['result']))
    check_txs(epoch, entry.dig('result', 'transactions') || [])
  end

  def check_txs(epoch, txs)
    node_txs = txs.each_index.map do |i|
      @rpc.call('eth_getTransactionByBlockNumberAndIndex', [hex(epoch), hex(i)])['result']
    end
    compare("#{label(epoch)} (eth_getTransactionByBlockNumberAndIndex, indices 0..#{txs.size - 1})",
            norm_txs(node_txs), norm_txs(txs))
  end

  def check_receipts(epoch, entry)
    resp = @rpc.call('eth_getBlockReceipts', [hex(epoch)])
    return null_round(epoch, resp, agreed: null_round_error?(resp), receipts: resp['result']&.size) if entry.nil?

    compare(label(epoch), resp['result'], entry['result'])
  end

  def check_tipsets(epoch, entry)
    resp = @rpc.call('Filecoin.ChainGetTipSetByHeight', [epoch, nil])
    if entry.nil?
      height = resp.dig('result', 'Height')
      return null_round(epoch, resp, agreed: height.is_a?(Integer) && height < epoch, height:)
    end
    compare(label(epoch), resp['result'], entry['result'])
  end

  def check_logs(epoch, entry)
    resp = @rpc.call('eth_getLogs', [{ fromBlock: hex(epoch), toBlock: hex(epoch) }])
    if entry.nil?
      agreed = resp['error'].nil? && resp['result'] == []
      return null_round(epoch, resp, agreed:, logs: resp['result']&.size)
    end
    compare(label(epoch), resp['result'], expected_logs(entry))
  end

  def label(epoch) = "#{@method} epoch #{epoch}"

  def compare(header, node, archive)
    diffs = deep_diff(node, archive)
    return if diffs.empty?

    fail_with("#{header}:", diffs)
  end

  def null_round(epoch, resp, agreed:, **detail)
    return if agreed

    fail_with("#{label(epoch)}: archive is a null round but the node did not agree:",
              [detail.merge(error: error_message(resp)).to_json])
  end

  def fail_with(header, lines)
    @failed = true
    @out << "MISMATCH #{header}"
    @out.concat(lines.first(DIFF_LIMIT).map { "  #{clip(it)}" })
    @out << "  … #{lines.size - DIFF_LIMIT} more" if lines.size > DIFF_LIMIT
  end

  def clip(line) = line.size > DIFF_LINE_LIMIT ? "#{line[0, DIFF_LINE_LIMIT]}… (#{line.size} chars)" : line
end

# Whether the dataset has published every archive day an epoch range needs.
class Probe
  attr_reader :out

  def initialize(range:, archive:, genesis:)
    @range = range
    @archive = archive
    @genesis = genesis
    @out = []
  end

  # :pass / :no_data (a day is missing) / :fail (dataset unreachable).
  def run
    published = days.product(ARCHIVE_FILES.values.uniq).map do |date, file|
      ok = @archive.published?(file, date)
      @out << "#{date} #{file}: #{ok ? 'published' : 'missing'}"
      ok
    end
    published.all? ? :pass : :no_data
  rescue StandardError => e
    @out << "ERROR #{e.message} (#{e.class})"
    :fail
  end

  private

  # Stepping a full day from the start visits each UTC day once; the range end
  # may still fall one day further.
  def days = @range.step(EPOCHS_IN_DAY).map { day(it) } | [day(@range.end)]

  def day(epoch) = locate(epoch, @genesis).first
end

# --- CLI ----------------------------------------------------------------------

def network_and_genesis(rpc_url)
  rpc = Rpc.new(rpc_url)
  name = rpc.call('Filecoin.StateNetworkName', [])['result']
  genesis = rpc.call('Filecoin.ChainGetGenesis', []).dig('result', 'Blocks', 0, 'Timestamp')
  net = NETWORKS[name]
  abort "No dataset for network #{name.inspect} (expected: #{NETWORKS.keys.join(', ')})" if net.nil?
  abort "Failed to fetch genesis timestamp from #{rpc_url}" unless genesis.is_a?(Integer)
  [net, genesis]
rescue StandardError => e
  abort "Failed to query the node at #{rpc_url}: #{e.message}"
end

def probe!(net, genesis, range)
  probe = Probe.new(range:, archive: Archive.new(net), genesis:)
  status = probe.run
  puts probe.out
  puts '', "=== probe (#{net}, epochs #{range.begin}..#{range.end}) === #{status.to_s.tr('_', '-').upcase}"
  exit({ pass: 0, no_data: 2 }.fetch(status, 1))
end

methods = Checker::METHODS
probing = false
network = nil
parser = OptionParser.new do |o|
  o.banner = <<~BANNER
    Usage: #{File.basename($PROGRAM_NAME)} [--only m1,m2,...] [--probe [--network net]] <start_epoch> [end_epoch]
      env: FOREST_RPC_URL overrides the node URL (default localhost:2345/rpc/v1)
           DATASET_URL overrides the dataset base (default #{DATASET_URL})
      The network is auto-detected from the node.
  BANNER
  o.on('--only LIST', Array, "Methods to run (#{methods.join(', ')}; default all)") { methods = it }
  o.on('--probe', 'Only check that the dataset has published the range; exit 2 if not') { probing = true }
  o.on('--network NET', GENESIS.keys, "With --probe, skip the node and probe NET (#{GENESIS.keys.join(', ')})") do |net|
    network = net
  end
end
begin
  parser.parse!
rescue OptionParser::ParseError => e
  abort "#{e.message}\n#{parser.help}"
end
abort "--network only applies with --probe\n#{parser.help}" if network && !probing
start_epoch, end_epoch, extra = ARGV
abort parser.help if start_epoch.nil? || !extra.nil?
unknown = methods - Checker::METHODS
abort "Unknown method(s): #{unknown.join(', ')} (expected: #{Checker::METHODS.join(', ')})" unless unknown.empty?

range = begin
  Integer(start_epoch)..Integer(end_epoch || start_epoch)
rescue ArgumentError
  abort "Epochs must be integers (note: the network argument is gone, it is auto-detected).\n#{parser.help}"
end
rpc_url = ENV.fetch('FOREST_RPC_URL', 'localhost:2345/rpc/v1')

net, genesis = network ? [network, GENESIS.fetch(network)] : network_and_genesis(rpc_url)
probe!(net, genesis, range) if probing

# Methods are independent, so each runs in its own thread; output is printed in a stable order.
archive = Archive.new(net)
runs = methods.map do |m|
  checker = Checker.new(method: m, range:, rpc_url:, archive:, genesis:)
  [m, checker, Thread.new { checker.run }]
end

summary = runs.to_h do |m, checker, thread|
  status = begin
    thread.value
  rescue StandardError => e
    checker.out << "ERROR #{m}: #{e.message} (#{e.class})"
    :fail
  end
  puts checker.out
  [m, status]
end

puts '', "=== summary (#{net}, epochs #{range.begin}..#{range.end}) ==="
summary.each { |m, s| puts "#{m.ljust(10)} #{s.to_s.tr('_', '-').upcase}" }

exit 1 if summary.value?(:fail)
exit 2 if summary.value?(:no_data)
