#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

# 1. Initialize s3cmd (if not already configured)
# 2. Run benchmark
# 3. Upload benchmark results to s3 bucket

# Initialize s3cmd using Ruby script (if not already configured)
ruby init_s3cmd.rb

## Run actual benchmark
ruby bench.rb --chain calibnet --tempdir ./snapshots --daily
ruby bench.rb --chain mainnet --tempdir ./snapshots --daily

## Upload benchmark result to s3 weekly file
week_number=$(date +%W) # Week starting on Monday
s3cmd get s3://"$BENCHMARK_BUCKET"/benchmark-results/weekly-results/weekly_result_"$week_number".csv /tmp/weekly_result_"$week_number".csv --force || 
echo "Timestamp,Forest Version,Lotus Version,Chain,Metric,Forest Value,Lotus Value" > /tmp/weekly_result_"$week_number".csv
tail -n +2 -q /chainsafe/result_*.csv >> /tmp/weekly_result_"$week_number".csv && s3cmd --acl-public put /tmp/weekly_result_"$week_number".csv s3://"$BENCHMARK_BUCKET"/benchmark-results/weekly-results/weekly_result_"$week_number".csv || exit 1

s3cmd get s3://"$BENCHMARK_BUCKET"/benchmark-results/all_results.csv /tmp/all_results.csv --force || 
echo "Timestamp,Forest Version,Lotus Version,Chain,Metric,Forest Value,Lotus Value" > /tmp/all_results.csv
tail -n +2 -q /chainsafe/result_*.csv >> /tmp/all_results.csv && s3cmd --acl-public put /tmp/all_results.csv s3://"$BENCHMARK_BUCKET"/benchmark-results/all_results.csv || exit 1
