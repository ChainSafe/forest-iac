#!/bin/bash

## Enable strict error handling
set -eux

sudo docker build -t benchmark .

echo "Starting benchmark docker service.."
sudo docker run --detach \
  --name forest-benchmark \
  --env AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  --env AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  --env BENCHMARK_BUCKET="$BENCHMARK_BUCKET" \
  --env BENCHMARK_ENDPOINT="$BENCHMARK_ENDPOINT" \
  --env BASE_FOLDER="$BASE_FOLDER" \
  --env SLACK_API_TOKEN="$SLACK_API_TOKEN" \
  --env SLACK_NOTIF_CHANNEL="$SLACK_NOTIF_CHANNEL" \
  --restart unless-stopped \
  benchmark \
  /bin/bash -c "ruby run_benchmark.rb"
