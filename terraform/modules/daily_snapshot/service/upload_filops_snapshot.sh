#!/bin/bash

set -euo pipefail

CHAIN="$1"

# Forest snapshot url
URL="https://forest.chainsafe.io/$CHAIN/snapshot-latest.car.zst"

# Fetch the actual URL after following redirection and Extract the file name
SNAPSHOT_URL=$(wget --spider -S "$URL" 2>&1 | grep "Location" | awk '{print $2}' | tr -d '\r' | tail -1)
SNAPSHOT_NAME=$(basename "${SNAPSHOT_URL}")

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
cd forest_db/filops && forest-tool snapshot fetch --chain $CHAIN --vendor filops

# Get the most recently downloaded snapshot's name
DOWNLOADED_SNAPSHOT_NAME=\$(basename \$(find . -name "filops_snapshot_$CHAIN*" -type f -print0 | xargs -r -0 ls -1 -t | head -1))

# Remove the '.zst' part from the filename
BASE_SNAPSHOT_NAME=\${DOWNLOADED_SNAPSHOT_NAME%.zst}
    
# Generate SHA-256 checksum
sha256sum ./\$DOWNLOADED_SNAPSHOT_NAME > \$BASE_SNAPSHOT_NAME.sha256sum
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

    if s3cmd --acl-public put "$BASE_FOLDER/forest_db/filops/filops_snapshot_$CHAIN"* s3://"$SNAPSHOT_BUCKET/$CHAIN/"; then
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
