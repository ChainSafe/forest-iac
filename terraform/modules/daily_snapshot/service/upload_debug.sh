#!/bin/bash

set -euo pipefail

LOG_NAME=$1
CHAIN=$2

send_slack_alert() {
    local message="$1"
    curl -X POST -H 'Content-type: application/json' -H "Authorization: Bearer $SLACK_API_TOKEN" \
    --data "{\"channel\":\"${SLACK_NOTIF_CHANNEL}\",\"text\":\"${message}\"}" \
    https://slack.com/api/chat.postMessage
}

if s3cmd --acl-public put "$BASE_FOLDER/$LOG_NAME" s3://"$DEBUG_BUCKET/$CHAIN/"; then
    send_slack_alert "$CHAIN debug logs uploaded successful:✅."
else
    echo "Failed to upload the debug logs."
    send_slack_alert "$CHAIN debug logs uploaded Failed:🔥."
fi
