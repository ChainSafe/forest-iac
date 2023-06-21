#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

## Configure s3cmd
s3cmd --dump-config \
    --host="$BENCHMARK_ENDPOINT" \
    --host-bucket="%(bucket)s.$BENCHMARK_ENDPOINT" \
    --access_key="$AWS_ACCESS_KEY_ID" \
    --secret_key="$AWS_SECRET_ACCESS_KEY" \
    --multipart-chunk-size-mb=4096 > ~/.s3cfg

## Run actual benchmark
ruby bench.rb --chain calibnet --tempdir ./benchmark --daily

## Upload benchmark result to s3 weekly file
week_number=$(date +%W) # Week starting on Monday
tail -n +2 /root/results_*.csv | s3cmd --acl-public put - s3://"$BENCHMARK_BUCKET"/weekly-results/weekly_result_$week_number.csv || exit 1

tail -n +2 /root/results_*.csv | s3cmd --acl-public put -  s3://"$BENCHMARK_BUCKET"/all-results/all_results.csv || exit 1
