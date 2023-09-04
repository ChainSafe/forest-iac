#!/bin/bash

## Enable strict error handling
set -eux

# 1. Initialize s3cmd
# 2. Run benchmark
# 3. Upload benchmark results to s3 bucket

## Configure s3cmd
CFG=~/.s3cfg

if [ ! -f "$CFG" ]; then
    s3cmd --dump-config \
        --host="$BENCHMARK_ENDPOINT" \
        --host-bucket="%(bucket)s.$BENCHMARK_ENDPOINT" \
        --access_key="$AWS_ACCESS_KEY_ID" \
        --secret_key="$AWS_SECRET_ACCESS_KEY" \
        --multipart-chunk-size-mb=4096 > "$CFG"
    echo "Configuration file created at $CFG"
else
    echo "s3cmd Configuration file exist at $CFG"
fi

## Run actual benchmark
ruby bench.rb --chain calibnet --tempdir ./tmp --daily
ruby bench.rb --chain mainnet --tempdir ./tmp --daily

## Upload benchmark result to s3 weekly file
year_number=$(date +%Y)
week_number=$(date +%W) # Week starting on Monday
weekly_file="weekly-results-$year_number-$week_number.csv"

s3cmd get s3://"$BENCHMARK_BUCKET"/benchmark-results/weekly-results/"$weekly_file" /tmp/"$weekly_file" --force || 
echo "Timestamp,Forest Version,Lotus Version,Chain,Metric,Forest Value,Lotus Value" > /tmp/"$weekly_file"
tail -n +2 -q /chainsafe/result_*.csv >> /tmp/"$weekly_file" && s3cmd --acl-public put /tmp/"$weekly_file" s3://"$BENCHMARK_BUCKET"/benchmark-results/weekly-results/"$weekly_file"
rm /tmp/"$weekly_file" -f

s3cmd get s3://"$BENCHMARK_BUCKET"/benchmark-results/all-results.csv /tmp/all-results.csv --force || 
echo "Timestamp,Forest Version,Lotus Version,Chain,Metric,Forest Value,Lotus Value" > /tmp/all-results.csv
tail -n +2 -q /chainsafe/result_*.csv >> /tmp/all-results.csv && s3cmd --acl-public put /tmp/all-results.csv s3://"$BENCHMARK_BUCKET"/benchmark-results/all-results.csv
rm /tmp/all-results.csv -f
