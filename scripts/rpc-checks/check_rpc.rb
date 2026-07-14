#!/usr/bin/env ruby
# frozen_string_literal: true

# Filecoin JSON-RPC verification against the https://chain.data.riba.plus
# dataset. Exit codes:
#   0 = all pass, 1 = any mismatch, 2 = no mismatches but an
#   archive day was unavailable (not yet published), so coverage is partial.
#
# Methods (select with --only, default all):
#   blocks   - eth_getBlockByNumber (+ eth_getTransactionByBlockNumberAndIndex
#              for every tx in the archive block)
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
# A diff line embeds whole JSON values; a null-vs-document mismatch would
# otherwise print the entire archive entry (100 KB+) on a single line.
DIFF_LINE_LIMIT = 512
# What counts as a transient network error, for both the node and the dataset.
NET_ERRORS = [IOError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout].freeze

# Node network name (Filecoin.StateNetworkName) -> dataset path segment.
NETWORKS = { 'mainnet' => 'mainnet', 'calibrationnet' => 'calibnet' }.freeze

# Method -> daily archive file in the dataset. logs has no archive of its own:
# its reference is derived from the receipts archive by flattening every
# receipt's logs.
ARCHIVE_FILES = {
  'blocks' => 'eth_getBlockByNumber',
  'receipts' => 'eth_getBlockReceipts',
  'tipsets' => 'Filecoin.ChainGetTipSetByHeight',
  'logs' => 'eth_getBlockReceipts'
}.freeze

# --- pure JSON-document helpers -----------------------------------------------

def hex(num) = format('0x%x', num)

# Known expected mismatches, dropped before comparing (remove as they get
# fixed): logsBloom — Forest returns an all-ones placeholder for the
# block-level bloom (PR #7156); accessList — the dataset normalizes the
# field to [] on legacy txs where the node omits it (issue #7205).
def norm_tx(txn) = txn.is_a?(Hash) ? txn.except('accessList') : txn

def norm_txs(txs) = txs.map { norm_tx(it) }

def norm_block(block)
  return block unless block.is_a?(Hash)

  block.except('logsBloom').tap do |b|
    b['transactions'] = norm_txs(b['transactions']) if b['transactions'].is_a?(Array)
  end
end

def error_message(resp) = resp.dig('error', 'message')

# The dedicated error that blocks/receipts must answer with on a null round.
def null_round_error?(resp) = resp['result'].nil? && error_message(resp).to_s.include?('null round')

# The logs reference: every receipt's logs from the receipts archive, flattened.
def expected_logs(entry) = (entry['result'] || []).flat_map { it['logs'] || [] }

# Differing paths between two JSON documents (semantic: key order never matters).
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

# Cap each side of a leaf diff line separately, so a huge node value can never
# push the archive side out of the clipped line (and vice versa).
def excerpt(value, limit = DIFF_LINE_LIMIT / 4)
  json = value.to_json
  json.size > limit ? "#{json[0, limit]}… (#{json.size} chars)" : json
end

def diff_arrays(node, archive, path)
  header = []
  header << "#{path}: array sizes differ (node=#{node.size}, archive=#{archive.size})" if node.size != archive.size
  header + node.take(archive.size).each_with_index.flat_map { |x, i| deep_diff(x, archive[i], "#{path}[#{i}]") }
end

# Minimal JSON-RPC client over a persistent connection (reconnects once if the
# server closed an idle keep-alive connection).
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

# Daily archive files, each downloaded (and brotli-inflated) once per run and
# shared across method threads — receipts and logs use the same file.
class Archive
  def initialize(net)
    @net = net
    @cache = {}
    @mutex = Mutex.new
  end

  # Lines of the day's ndjson, or nil if the day isn't published. The cache
  # holds one in-flight fetch per (file, date): same-key callers share it,
  # different keys download concurrently — the lock only guards the insert.
  def daily(file, date)
    @mutex.synchronize { @cache[[file, date]] ||= Thread.new { fetch(file, date) } }.value
  end

  private

  def fetch(file, date, attempts: 3)
    uri = URI("https://chain.data.riba.plus/fil/#{@net}/daily/#{date}/#{file}.v1.r1.ndjson.brotli")
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

  # The server only sends the compact brotli bytes to clients that ask for
  # them (and decompresses transparently otherwise), so inflate iff marked.
  def download(uri)
    uri.open('Accept-Encoding' => 'br') do |f|
      f.content_encoding.include?('br') ? Brotli.inflate(f.read) : f.read
    end
  end
end

# One verification method over an epoch range: walks the daily archive files in
# lockstep with the epoch counter and diffs every entry against the node.
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

  # Checks the epochs from `epoch` to the end of its UTC day (or of the range);
  # returns the next epoch to check, or nil if the archive day ran out.
  def check_day(epoch)
    date, line = locate(epoch)
    day_end = [epoch + EPOCHS_IN_DAY - line, @range.end].min
    @out << "--- #{@method}: epochs #{epoch}..#{day_end} (#{date}, #{ARCHIVE_FILES[@method]}) ---"
    (epoch..day_end).zip(day_entries(date, line)) do |e, raw|
      # A missing or empty entry means the daily file is unavailable or
      # truncated (e.g. the current, not-yet-published day); the archive
      # publishes chronologically, so every later epoch is missing too.
      if raw.to_s.strip.empty?
        @out << "no archive for #{date} (day not published?); stopping #{@method} at epoch #{e}."
        return nil
      end
      send("check_#{@method}", e, JSON.parse(raw))
    end
    day_end + 1
  end

  def day_entries(date, line) = @archive.daily(ARCHIVE_FILES[@method], date)&.drop(line - 1) || []

  # The archive's daily files are partitioned on midnight UTC, so an epoch's
  # day is its own UTC date and its line is 1 + its offset from that day's
  # first (midnight) epoch. (Relies on genesis % SECONDS_IN_EPOCH == 0, which
  # holds on both networks.)
  def locate(epoch)
    ts = (epoch * SECONDS_IN_EPOCH) + @genesis
    [Time.at(ts, in: 'UTC').strftime('%Y/%m/%d'), 1 + (ts % SECONDS_IN_DAY / SECONDS_IN_EPOCH)]
  end

  # --- per-method checks ----------------------------------------------------
  # Null-round semantics: blocks/receipts must answer with the dedicated
  # "requested epoch was a null round" error (any other response — including
  # other errors, e.g. missing state — is a discrepancy); logs must return an
  # empty list; tipsets walks back to the nearest lower non-null tipset, so it
  # agrees iff the returned Height < epoch.

  def check_blocks(epoch, entry)
    resp = @rpc.call('eth_getBlockByNumber', [hex(epoch), true])
    return null_round(epoch, resp, agreed: null_round_error?(resp), number: resp.dig('result', 'number')) if entry.nil?

    compare(label(epoch), norm_block(resp['result']), norm_block(entry['result']))
    check_txs(epoch, entry.dig('result', 'transactions') || [])
  end

  # Every tx the archive block carries must be returned identically by the
  # node's per-index endpoint; called once per index, compared in one batch.
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

  # --- reporting --------------------------------------------------------------

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

# --- CLI ----------------------------------------------------------------------

methods = Checker::METHODS
parser = OptionParser.new do |o|
  o.banner = <<~BANNER
    Usage: #{File.basename($PROGRAM_NAME)} [--only m1,m2,...] <start_epoch> [end_epoch]
      env: FOREST_RPC_URL overrides the node URL (default localhost:2345/rpc/v1)
      The network is auto-detected from the node.
  BANNER
  o.on('--only LIST', Array, "Methods to run (#{methods.join(', ')}; default all)") { methods = it }
end
begin
  parser.parse!
rescue OptionParser::ParseError => e
  abort "#{e.message}\n#{parser.help}"
end
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

# The network and the genesis timestamp both come from the node itself, so the
# right dataset is always compared against, whatever the node runs.
begin
  rpc = Rpc.new(rpc_url)
  network_name = rpc.call('Filecoin.StateNetworkName', [])['result']
  genesis = rpc.call('Filecoin.ChainGetGenesis', []).dig('result', 'Blocks', 0, 'Timestamp')
rescue StandardError => e
  abort "Failed to query the node at #{rpc_url}: #{e.message}"
end
abort "Failed to fetch network name from #{rpc_url}" if network_name.nil?
net = NETWORKS[network_name]
abort "No dataset for network #{network_name.inspect} (expected: #{NETWORKS.keys.join(', ')})" if net.nil?
abort "Failed to fetch genesis timestamp from #{rpc_url}" unless genesis.is_a?(Integer)

# The methods are independent: run each in its own thread (blocks alone makes
# ~1+ntx node calls per epoch and would otherwise dominate a sequential run)
# and print the buffered outputs in a stable order.
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
