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

ruby daily_snapshot.rb "$NETWORK_CHAIN"
