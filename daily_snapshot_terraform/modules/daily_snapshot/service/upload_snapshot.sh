#!/bin/bash

# If Forest hasn't synced to the network after 8 hours, something has gone wrong.
SYNC_TIMEOUT=8h

if [[ $# != 2 ]]; then
  echo "Usage: bash $0 CHAIN_NAME SNAPSHOT_PATH"
  exit 1
fi

CHAIN_NAME=$1
NEWEST_SNAPSHOT=$2

# Make sure we have the most recent Forest image
docker pull ghcr.io/chainsafe/forest:"${FOREST_TAG}"

# Sync and export is done in a single container to make sure everything is
# properly cleaned up.
COMMANDS=$(cat << HEREDOC
set -eux

# Install utility binaries that do not come with the image.
# This assumes the container was started as a superuser.
apt-get update && apt-get install -y curl

# Switch back to the service user for other service commands.
su - forest

# periodically write metrics to a file
# this is done in a separate process to avoid blocking the sync process
# and to ensure that the metrics are written even if it crashes
function write_metrics {
  while true; do
    curl --silent --fail --output metrics.txt --max-time 5 --retry 5 --retry-delay 2 --retry-max-time 10 http://localhost:6116/metrics || true
    sleep 5
  done
}

function print_forest_logs {
  cat forest.err forest.out metrics.txt
}
trap print_forest_logs EXIT

echo "[client]" > config.toml
echo 'data_dir = "/home/forest/forest_db"' >> config.toml
echo 'encrypt_keystore = false' >> config.toml

# In case of failures, more elaborate logging may
# help with debugging. We are doing this only for calibnet
# because enabling this for mainnet might result in a huge
# log file and bad performance.
if [ "$CHAIN_NAME" = "calibnet" ]; then
  export RUST_LOG=debug
fi

echo "Chain: $CHAIN_NAME"
echo "Snapshot: $NEWEST_SNAPSHOT"

# spawn a task in the background to periodically write Prometheus metrics to a file
write_metrics &

forest-cli --config config.toml --chain "$CHAIN_NAME" db clean --force
forest --config config.toml --chain "$CHAIN_NAME" --import-snapshot "$NEWEST_SNAPSHOT" --halt-after-import
forest --config config.toml --chain "$CHAIN_NAME" --no-gc --detach
timeout "$SYNC_TIMEOUT" forest-cli --chain "$CHAIN_NAME" sync wait
forest-cli --chain "$CHAIN_NAME" snapshot export -o forest_db/
forest-cli archive info forest_db/forest_snapshot_$CHAIN_NAME"*.forest.car.zst
forest-cli snapshot validate --check-links 0 --check-network "$CHAIN_NAME" forest_db/forest_snapshot_$CHAIN_NAME"*.forest.car.zst

# Kill the metrics writer process
kill %1

HEREDOC
)

# Stop any lingering docker containers
docker stop forest-snapshot-upload-node-"$CHAIN_NAME"

# Run forest and generate a snapshot in forest_db/
docker run \
  --name forest-snapshot-upload-node-"$CHAIN_NAME" \
  --rm \
  --user root \
  -v "$BASE_FOLDER/forest_db:/home/forest/forest_db":z \
  --entrypoint /bin/bash \
  ghcr.io/chainsafe/forest:"${FOREST_TAG}" \
  -c "$COMMANDS" || exit 1

# Upload snapshot to s3
s3cmd --acl-public put "$BASE_FOLDER/forest_db/forest_snapshot_$CHAIN_NAME"* s3://"$SNAPSHOT_BUCKET"/"$CHAIN_NAME"/ || exit 1

# Delete snapshot files
rm "$BASE_FOLDER/forest_db/forest_snapshot_$CHAIN_NAME"*

