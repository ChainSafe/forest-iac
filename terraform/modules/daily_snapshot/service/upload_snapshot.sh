#!/bin/bash

# If Forest hasn't synced to the network after 8 hours, something has gone wrong.
SYNC_TIMEOUT=8h

if [[ $# != 1 ]]; then
  echo "Usage: bash $0 CHAIN_NAME"
  exit 1
fi

CHAIN_NAME=$1

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

echo "Chain: $CHAIN_NAME"

# spawn a task in the background to periodically write Prometheus metrics to a file
write_metrics &

forest-tool db destroy --force --config config.toml --chain "$CHAIN_NAME"

forest --config config.toml --chain "$CHAIN_NAME" --auto-download-snapshot --halt-after-import
forest --config config.toml --chain "$CHAIN_NAME" --no-gc --save-token=token.txt --detach
timeout "$SYNC_TIMEOUT" forest-cli --chain "$CHAIN_NAME" sync wait
# Forest isn't waiting until fully synced. Tracking issue: https://github.com/ChainSafe/forest/issues/3540
# Calling 'sync wait' multiple times is a work-around.
timeout "$SYNC_TIMEOUT" forest-cli --chain "$CHAIN_NAME" sync wait
timeout "$SYNC_TIMEOUT" forest-cli --chain "$CHAIN_NAME" sync wait
timeout "$SYNC_TIMEOUT" forest-cli --chain "$CHAIN_NAME" sync wait
forest-cli --chain "$CHAIN_NAME" snapshot export -o forest_db/
forest-cli --token=\$(cat token.txt) shutdown --force

# Run full checks only for calibnet, given that it takes too long for mainnet.
if [ "$CHAIN_NAME" = "calibnet" ]; then
  forest-tool snapshot validate --check-network "$CHAIN_NAME" forest_db/forest_snapshot_*.forest.car.zst
else
  forest-tool archive info forest_db/forest_snapshot_*.forest.car.zst
  forest-tool snapshot validate --check-links 0 --check-network "$CHAIN_NAME" --check-stateroots 5 forest_db/forest_snapshot_*.forest.car.zst
fi


# Kill the metrics writer process
kill %1

HEREDOC
)

# Stop any lingering docker containers
CONTAINER_NAME="forest-snapshot-upload-node-$CHAIN_NAME"
docker stop "$CONTAINER_NAME" || true
docker rm --force "$CONTAINER_NAME"

CHAIN_DB_DIR="$BASE_FOLDER/forest_db/$CHAIN_NAME"

# Delete any existing snapshot files. It may be that the previous run failed
# before deleting those.
rm "$CHAIN_DB_DIR/forest_snapshot_$CHAIN_NAME"*

# Run forest and generate a snapshot in forest_db/
docker run \
  --name "$CONTAINER_NAME" \
  --rm \
  --user root \
  -v "$CHAIN_DB_DIR:/home/forest/forest_db":z \
  --entrypoint /bin/bash \
  ghcr.io/chainsafe/forest:"${FOREST_TAG}" \
  -c "$COMMANDS" || exit 1

aws --endpoint "$R2_ENDPOINT" s3 cp --no-progress "$CHAIN_DB_DIR/forest_snapshot_$CHAIN_NAME"*.forest.car.zst s3://forest-archive/"$CHAIN_NAME"/latest/ || exit 1

# Delete snapshot files
rm "$CHAIN_DB_DIR/forest_snapshot_$CHAIN_NAME"*
