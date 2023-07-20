#!/bin/bash

CHAIN="$1"

# URL to check
URL="https://forest.chainsafe.io/$CHAIN/snapshot-latest.car.zst"

# Fetch the actual URL after following redirection
SNAPSHOT_URL=$(wget --spider -S $URL 2>&1 | grep "Location" | awk '{print $2}' | tr -d '\r' | tail -1)

# Extract the file name
SNAPSHOT_NAME=$(basename $SNAPSHOT_URL)

# Extract the date from the snapshot file name
SNAPSHOT_DATE=$(echo $SNAPSHOT_NAME | cut -d'_' -f4)

# Convert the snapshot date to Unix timestamp (at start of the day)
SNAPSHOT_TIMESTAMP=$(date -u -d "$SNAPSHOT_DATE" +%s)

# Get current Unix timestamp (at start of the day)
CURRENT_TIMESTAMP=$(date -u -d "$(date -u +%Y-%m-%d)" +%s)

# Difference in timestamps, in days
DIFF=$(( (CURRENT_TIMESTAMP - SNAPSHOT_TIMESTAMP) / 86400 ))

# Get current date in YYYY-MM-DD format
CURRENT_DATE=$(date -u +%Y-%m-%d)

# Print the dates and difference
echo "The date of the snapshot is $SNAPSHOT_DATE. The current date is $CURRENT_DATE."

# Create the config.toml file in the forest_data directory.
cat << EOF > "/root/forest_db/config.toml"
[client]
data_dir = "/home/forest/forest_db/data"
encrypt_keystore = false
EOF

COMMANDS=$(cat << HEREDOC
set -eux
apt-get update && apt-get install -y curl
cat << EOF > "config.toml"
[client]
data_dir = "/home/forest/forest_db/data"
encrypt_keystore = false
EOF
forest --config config.toml --chain "$CHAIN" --detach
cd /home/forest/forest_db/data && forest-cli snapshot fetch --vendor filops

# Get the most recently downloaded snapshot's name
DOWNLOADED_SNAPSHOT_NAME=$(ls -tr | grep "^filops_snapshot_$CHAIN_*" | tail -n 1)

# Remove the '.zst' part from the filename
BASE_SNAPSHOT_NAME=${DOWNLOADED_SNAPSHOT_NAME%.zst}
    
# Generate SHA-256 checksum
sha256sum $DOWNLOADED_SNAPSHOT_NAME > $BASE_SNAPSHOT_NAME.sha256sum
HEREDOC
)

# If the difference is more than one day, run the command
# Function to send Slack alert
send_slack_alert() {
    local message="$1"
    curl -X POST -H 'Content-type: application/json' -H "Authorization: Bearer $SLACK_TOKEN" \
    --data "{\"channel\":\"#forest-dump\",\"text\":\"${message}\"}" \
    https://slack.com/api/chat.postMessage
}

# If the difference is more than one day, run the command
if [ $DIFF -gt 1 ]; then
    echo "The snapshot is older than one day."
    docker run \
      --name filops-snapshot-upload-node-"$CHAIN" \
      --rm \
      --user root \
      --volume=/root/forest_db:/home/forest/forest_db/data \
      --entrypoint /bin/bash \
      ghcr.io/chainsafe/forest:latest \
      -c "$COMMANDS" || exit 1  
    if s3cmd --acl-public put "$BASE_FOLDER/forest_db/filops_snapshot_$CHAIN_NAME"* s3://"$SNAPSHOT_BUCKET"/"$CHAIN_NAME"/; then
        rm "$BASE_FOLDER/forest_db/filops_snapshot_$CHAIN_NAME"*
        # Send alert to Slack only if upload is successful
        send_slack_alert "Old snapshot detected. 🔥🌲🔥. Filops Snapshot upload failed:✅"
    else
        echo "Failed to upload the snapshot."
        # Send alert to Slack for failed upload
        send_slack_alert "Old snapshot detected. 🔥🌲🔥. Filops Snapshot upload failed:🔥" 
    fi
else
    echo "The snapshot is from today or yesterday."
fi




docker run \
  --name filops-snapshot-upload-node-"$CHAIN" \
  --rm \
  --user root \
  --volume=/root/forest_db:/home/forest/forest_db/data \
  --entrypoint /bin/bash \
  ghcr.io/chainsafe/forest:latest \
  -c "$COMMANDS"
