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
require 'optparse'
require 'brotli'

SECONDS_IN_EPOCH = 30
SECONDS_IN_DAY = 24 * 60 * 60
EPOCHS_IN_DAY = SECONDS_IN_DAY / SECONDS_IN_EPOCH
DIFF_LIMIT = 20

# Method -> daily archive file in the dataset. logs has no archive of its own:
# its reference is derived from the receipts archive by flattening every
# receipt's logs.
ARCHIVE_FILES = {
  'blocks' => 'eth_getBlockByNumber',
  'receipts' => 'eth_getBlockReceipts',
  'tipsets' => 'Filecoin.ChainGetTipSetByHeight',
  'logs' => 'eth_getBlockReceipts'
}.freeze

def hex(n) = format('0x%x', n)

# Minimal JSON-RPC client over a persistent connection (reconnects once if the
# server closed an idle keep-alive connection).
class Rpc
  def initialize(url)
    @uri = URI(url.include?('://') ? url : "http://#{url}")
  end

  def call(method, params)
    request = Net::HTTP::Post.new(@uri.request_uri, 'Content-Type' => 'application/json')
    request.body = { jsonrpc: '2.0', id: 1, method:, params: }.to_json
    JSON.parse(http.request(request).body)
  rescue IOError, EOFError, SystemCallError
    @http = nil
    JSON.parse(http.request(request).body)
  end

  private

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

  # Lines of the day's ndjson, or nil if the day isn't published.
  def daily(file, date)
    @mutex.synchronize { @cache.fetch([file, date]) { @cache[[file, date]] = fetch(file, date) } }
  end

  private

  def fetch(file, date, attempts: 3)
    uri = URI("https://chain.data.riba.plus/fil/#{@net}/daily/#{date}/#{file}.v1.r1.ndjson.brotli")
    attempts.times do |i|
      case res = get(uri)
      # The server only sends the compact brotli bytes to clients that ask for
      # them (and decompresses transparently otherwise), so inflate iff marked.
      when Net::HTTPSuccess
        return (res['content-encoding'] == 'br' ? Brotli.inflate(res.body) : res.body).lines
      when Net::HTTPNotFound then return nil
      else sleep 1 + i
      end
    end
    nil
  end

  def get(uri, hops = 3)
    res = Net::HTTP.get_response(uri, 'Accept-Encoding' => 'br')
    res.is_a?(Net::HTTPRedirection) && hops.positive? ? get(URI(res['location']), hops - 1) : res
  rescue IOError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout
    nil
  end
end

# One verification method over an epoch range: walks the daily archive files in
# lockstep with the epoch counter and diffs every entry against the node.
class Checker
  METHODS = ARCHIVE_FILES.keys.freeze

  attr_reader :out

  def initialize(method:, range:, rpc_url:, archive:, genesis:)
    @method, @range, @archive, @genesis = method, range, archive, genesis
    @rpc = Rpc.new(rpc_url)
    @out = []
    @failed = false
  end

  # :pass / :fail (mismatch) / :no_data (archive day unavailable).
  def run
    epoch = @range.begin
    while epoch <= @range.end
      date, line = locate(epoch)
      day_end = [epoch + EPOCHS_IN_DAY - line, @range.end].min
      @out << "--- #{@method}: epochs #{epoch}..#{day_end} (#{date}, #{ARCHIVE_FILES[@method]}) ---"
      entries = @archive.daily(ARCHIVE_FILES[@method], date)&.drop(line - 1) || []
      (epoch..day_end).zip(entries) do |e, raw|
        # A missing or empty entry means the daily file is unavailable or
        # truncated (e.g. the current, not-yet-published day); the archive
        # publishes chronologically, so every later epoch is missing too.
        if raw.nil? || raw.strip.empty?
          @out << "no archive for #{date} (day not published?); stopping #{@method} at epoch #{e}."
          return @failed ? :fail : :no_data
        end
        check(e, JSON.parse(raw))
      end
      epoch = day_end + 1
    end
    @failed ? :fail : :pass
  end

  private

  def check(epoch, entry) = send("check_#{@method}", epoch, entry)

  # The archive's daily files are partitioned on midnight UTC, so an epoch's
  # day is its own UTC date and its line is 1 + its offset from that day's
  # first (midnight) epoch. (Relies on genesis % SECONDS_IN_EPOCH == 0, which
  # holds on both networks.)
  def locate(epoch)
    ts = epoch * SECONDS_IN_EPOCH + @genesis
    [Time.at(ts, in: 'UTC').strftime('%Y/%m/%d'), 1 + ts % SECONDS_IN_DAY / SECONDS_IN_EPOCH]
  end

  # --- per-method checks ----------------------------------------------------
  # Null-round semantics: blocks/receipts must answer with the dedicated
  # "requested epoch was a null round" error (any other response — including
  # other errors, e.g. missing state — is a discrepancy); logs must return an
  # empty list; tipsets walks back to the nearest lower non-null tipset, so it
  # agrees iff the returned Height < epoch.

  def check_blocks(epoch, entry)
    resp = @rpc.call('eth_getBlockByNumber', [hex(epoch), true])
    if entry.nil?
      return null_round(label(epoch), resp, null_round_error?(resp),
                        number: resp.dig('result', 'number'))
    end
    compare(label(epoch), norm_block(resp['result']), norm_block(entry['result']))
    # Every tx the archive block carries must be returned identically by the
    # node's per-index endpoint; called once per index, compared in one batch.
    txs = entry.dig('result', 'transactions') || []
    node_txs = txs.each_index.map { @rpc.call('eth_getTransactionByBlockNumberAndIndex', [hex(epoch), hex(_1)])['result'] }
    compare("#{label(epoch)} (eth_getTransactionByBlockNumberAndIndex, indices 0..#{txs.size - 1})",
            node_txs.map { norm_tx(_1) }, txs.map { norm_tx(_1) })
  end

  def check_receipts(epoch, entry)
    resp = @rpc.call('eth_getBlockReceipts', [hex(epoch)])
    if entry.nil?
      return null_round(label(epoch), resp, null_round_error?(resp),
                        receipts: resp['result']&.size)
    end
    compare(label(epoch), resp['result'], entry['result'])
  end

  def check_tipsets(epoch, entry)
    resp = @rpc.call('Filecoin.ChainGetTipSetByHeight', [epoch, nil])
    if entry.nil?
      height = resp.dig('result', 'Height')
      return null_round(label(epoch), resp, height.is_a?(Integer) && height < epoch,
                        height:)
    end
    compare(label(epoch), resp['result'], entry['result'])
  end

  def check_logs(epoch, entry)
    resp = @rpc.call('eth_getLogs', [{ fromBlock: hex(epoch), toBlock: hex(epoch) }])
    if entry.nil?
      return null_round(label(epoch), resp, resp['error'].nil? && resp['result'] == [],
                        logs: resp['result']&.size)
    end
    expected = (entry['result'] || []).flat_map { _1['logs'] || [] }
    compare(label(epoch), resp['result'], expected)
  end

  def label(epoch) = "#{@method} epoch #{epoch}"

  def null_round_error?(resp)
    resp['result'].nil? && resp.dig('error', 'message').to_s.include?('null round')
  end

  # --- comparison and reporting ----------------------------------------------

  # Known expected mismatches, dropped before comparing (remove as they get
  # fixed): logsBloom — Forest returns an all-ones placeholder for the
  # block-level bloom (PR #7156); accessList — the dataset normalizes the
  # field to [] on legacy txs where the node omits it (issue #7205).
  def norm_tx(tx) = tx.is_a?(Hash) ? tx.except('accessList') : tx

  def norm_block(block)
    return block unless block.is_a?(Hash)

    block.except('logsBloom').tap do |b|
      b['transactions'] = b['transactions'].map { norm_tx(_1) } if b['transactions'].is_a?(Array)
    end
  end

  def compare(label, node, archive)
    diffs = deep_diff(node, archive)
    return if diffs.empty?

    fail_with("MISMATCH #{label}:", diffs)
  end

  def null_round(label, resp, agreed, detail)
    return if agreed

    fail_with("MISMATCH #{label}: archive is a null round but the node did not agree:",
              [detail.merge(error: resp.dig('error', 'message')).to_json])
  end

  def fail_with(header, lines)
    @failed = true
    @out << header
    @out.concat(lines.first(DIFF_LIMIT).map { "  #{_1}" })
    @out << "  … #{lines.size - DIFF_LIMIT} more" if lines.size > DIFF_LIMIT
  end

  # Differing paths between two JSON documents (semantic: key order never matters).
  def deep_diff(node, archive, path = '$')
    return [] if node == archive

    case [node, archive]
    in [Hash => a, Hash => b]
      (a.keys | b.keys).flat_map { deep_diff(a[_1], b[_1], "#{path}.#{_1}") }
    in [Array => a, Array => b]
      header = a.size == b.size ? [] : ["#{path}: array sizes differ (node=#{a.size}, archive=#{b.size})"]
      header + a.take(b.size).zip(b).each_with_index.flat_map { |(x, y), i| deep_diff(x, y, "#{path}[#{i}]") }
    else
      ["#{path}: node=#{node.to_json} archive=#{archive.to_json}"]
    end
  end
end

# --- CLI ----------------------------------------------------------------------

methods = Checker::METHODS
parser = OptionParser.new do |o|
  o.banner = "Usage: #{File.basename($PROGRAM_NAME)} [--only m1,m2,...] <network> <start_epoch> [end_epoch]\n" \
             "  env: FOREST_RPC_URL overrides the node URL (default localhost:2345/rpc/v1)"
  o.on('--only LIST', Array, "Methods to run (#{methods.join(', ')}; default all)") { methods = _1 }
end
begin
  parser.parse!
rescue OptionParser::ParseError => e
  abort "#{e.message}\n#{parser.help}"
end
net, start_epoch, end_epoch = ARGV
abort parser.help if net.nil? || start_epoch.nil?
abort "Unknown network: #{net}" unless %w[mainnet calibnet].include?(net)
unknown = methods - Checker::METHODS
abort "Unknown method(s): #{unknown.join(', ')} (expected: #{Checker::METHODS.join(', ')})" unless unknown.empty?

range = Integer(start_epoch)..Integer(end_epoch || start_epoch)
rpc_url = ENV.fetch('FOREST_RPC_URL', 'localhost:2345/rpc/v1')

# Genesis timestamp comes from the node itself, so it stays correct across networks.
genesis = begin
  Rpc.new(rpc_url).call('Filecoin.ChainGetGenesis', []).dig('result', 'Blocks', 0, 'Timestamp')
rescue StandardError
  nil
end
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
summary.each { |m, s| puts format('%-10s %s', m, s.to_s.tr('_', '-').upcase) }

# Any mismatch (1); otherwise partial coverage (2); otherwise 0.
exit 1 if summary.value?(:fail)
exit 2 if summary.value?(:no_data)
