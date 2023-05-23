#!/bin/bash

# If Forest hasn't synced to the network after 8 hours, something has gone wrong.
SYNC_TIMEOUT=8h
DOCKER_TIMEOUT=24h

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
echo "[client]" > config.toml
echo 'data_dir = "/home/forest/forest_db"' >> config.toml
echo 'encrypt_keystore = false' >> config.toml

echo "Chain: $CHAIN_NAME"
echo "Snapshot: $NEWEST_SNAPSHOT"
forest-cli --config config.toml --chain $CHAIN_NAME db clean --force
forest --config config.toml --chain $CHAIN_NAME --import-snapshot $NEWEST_SNAPSHOT --halt-after-import
forest --config config.toml --chain $CHAIN_NAME --detach || { echo "failed starting forest daemon"; exit 1; }
timeout $SYNC_TIMEOUT forest-cli --chain $CHAIN_NAME sync wait || { echo "timed-out on forest-cli sync"; exit 1; }
cat forest.err forest.out
forest-cli --chain $CHAIN_NAME snapshot export -o forest_db/ || { echo "failed to export the snapshot"; exit 1; }
HEREDOC
)

# Run forest and generate a snapshot in forest_db/
timeout $DOCKER_TIMEOUT docker run \
  --name forest-snapshot-upload-node-"$CHAIN_NAME" \
  --rm \
  -v "$BASE_FOLDER/forest_db:/home/forest/forest_db":z \
  --entrypoint /bin/bash \
  ghcr.io/chainsafe/forest:"${FOREST_TAG}" \
  -c "$COMMANDS" || exit 1

# Compress with zstd and add to checksum file
cd "$BASE_FOLDER/forest_db/" && zstd "forest_snapshot_$CHAIN_NAME"*.car
echo "" >> "$BASE_FOLDER/forest_db/forest_snapshot_$CHAIN_NAME"*.sha256sum
cd "$BASE_FOLDER/forest_db/" && (sha256sum "forest_snapshot_$CHAIN_NAME"*.car.zst >> "forest_snapshot_$CHAIN_NAME"*.sha256sum)

# Upload snapshot to s3
s3cmd --acl-public put "$BASE_FOLDER/forest_db/forest_snapshot_$CHAIN_NAME"* s3://"$SNAPSHOT_BUCKET"/"$CHAIN_NAME"/ || exit 1

# Delete snapshot files
rm "$BASE_FOLDER/forest_db/forest_snapshot_$CHAIN_NAME"*
