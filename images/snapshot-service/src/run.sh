#!/bin/bash

set -euo pipefail

# Assert that all required environment variables are set
: "${R2_ACCESS_KEY:?}"
: "${R2_SECRET_KEY:?}"
: "${R2_ENDPOINT:?}"
: "${SNAPSHOT_BUCKET:?}"
: "${SLACK_API_TOKEN:?}"
: "${SLACK_NOTIFICATION_CHANNEL:?}"
: "${NETWORK_CHAIN:?}"
: "${FOREST_TAG:?}"

aws configure set default.s3.multipart_chunksize 4GB
aws configure set aws_access_key_id "$R2_ACCESS_KEY"
aws configure set aws_secret_access_key "$R2_SECRET_KEY"

ruby daily_snapshot.rb "$NETWORK_CHAIN"
