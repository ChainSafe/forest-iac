#!/bin/bash

set -euo pipefail

CHAIN="$1"

# Ask curl for the filename of the snapshot
SNAPSHOT_NAME=$(curl --remote-name --remote-header-name --write-out "%{filename_effective}" --silent https://forest-archive.chainsafe.dev/latest/"$CHAIN"/ -H "Range: bytes=0-0")
rm -f "$SNAPSHOT_NAME"

# Extract the date from the snapshot file name and
# Convert the snapshot date to Unix timestamp (at start of the day)
SNAPSHOT_DATE=$(echo "${SNAPSHOT_NAME}" | cut -d'_' -f4)

# Convert the snapshot date to Unix timestamp (at start of the day)
SNAPSHOT_TIMESTAMP=$(date -u -d "${SNAPSHOT_DATE}" +%s)

# Get current Unix timestamp (at start of the day)
CURRENT_TIMESTAMP=$(date -u -d "$(date -u +%Y-%m-%d)" +%s)

# Difference in timestamps, in days
DIFF=$(( (CURRENT_TIMESTAMP - SNAPSHOT_TIMESTAMP) / 86400 ))

# Function to send Slack alert
send_slack_alert() {
    local message="$1"
    curl -X POST -H 'Content-type: application/json' -H "Authorization: Bearer $SLACK_API_TOKEN" \
    --data "{\"channel\":\"${SLACK_NOTIF_CHANNEL}\",\"text\":\"${message}\"}" \
    https://slack.com/api/chat.postMessage
}

COMMANDS=$(cat << HEREDOC
set -eux
cd forest_db/filops
forest-tool snapshot fetch --vendor filops --chain $CHAIN
HEREDOC
)

# If the snapshot is older than a day
# download the filops snapshot and generate the sha256sum file, then
# upload snapshots and sha256 file to the forest-snapshot bucket.
if [ ${DIFF} -gt 1 ]; then
    echo "The snapshot is older than one day."
    docker run \
      --name filops-snapshot-upload-node-"$CHAIN" \
      --rm \
      --user root \
      --volume=/root/forest_db:/home/forest/forest_db \
      --entrypoint /bin/bash \
      ghcr.io/chainsafe/forest:"${FOREST_TAG}" \
      -c "$COMMANDS" || exit 1

    if aws --endpoint "$R2_ENDPOINT" s3 cp "$BASE_FOLDER/forest_db/filops/filops_snapshot_$CHAIN"* s3://forest-archive/"$CHAIN_NAME"/latest/; then
        # Send alert to Slack only if upload is successful
        send_slack_alert "Old $CHAIN snapshot detected. 🔥🌲🔥. Filops Snapshot upload successful:✅"
        rm "$BASE_FOLDER/forest_db/filops/filops_snapshot_$CHAIN"*
    else
        echo "Failed to upload the snapshot."
        # Send alert to Slack for failed upload
        send_slack_alert "Old $CHAIN snapshot detected. 🔥🌲🔥. Filops Snapshot upload failed:🔥"
        exit 1
    fi
else
    echo "The snapshot is from today or yesterday."
fi
