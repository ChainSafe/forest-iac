#!/bin/bash

set -euo pipefail

# Function to send Slack alert
send_slack_alert() {
    local message="$1"
    curl -X POST -H 'Content-type: application/json' -H "Authorization: Bearer $SLACK_API_TOKEN" \
    --data "{\"channel\":\"${SLACK_NOTIF_CHANNEL}\",\"text\":\"${message}\"}" \
    https://slack.com/api/chat.postMessage
}

COMMANDS=$(cat << HEREDOC
set -eux
apt-get update && apt-get install -y zstd
cd snapshot/

forest-tool snapshot fetch --vendor filops --chain mainnet
forest-tool snapshot fetch --vendor forest --chain mainnet
zstd -d filops_*.car.zst
forest-tool archive export filops_*.car -o exported_snapshot.car.zst
HEREDOC
)

docker run \
  --name compare-snapshot \
  --rm \
  --user root \
   --volume=/root/snapshot:/home/forest/snapshot \
  --entrypoint /bin/bash \
  ghcr.io/chainsafe/forest:latest \
  -c "$COMMANDS" || exit 1

cd /root/snapshot
zstd -d exported_snapshot.car.zst

if cmp --silent filops_*.car exported_snapshot.car; then
    echo "Snapshots are identical."
else
    echo "Snapshot not identical"
    send_slack_alert "Checksum failed. 🔥🌲🔥. Snapshots do not match byte-for-byte with filops snapshot"
fi
