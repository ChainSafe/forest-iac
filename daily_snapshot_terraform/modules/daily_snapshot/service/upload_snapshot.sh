#!/bin/bash

# If Forest hasn't synced to the network after 90 minutes, something has gone wrong.
SYNC_TIMEOUT=90m

if [[ $# != 2 ]]; then
  echo "Usage: bash $0 CHAIN_NAME SNAPSHOT_PATH"
  exit 1
fi

CHAIN_NAME=$1
NEWEST_SNAPSHOT=$2

# Make sure we have the most recent Forest image
docker pull ghcr.io/chainsafe/forest:"${FOREST_TAG}"

# Ensure that we can access files with the default Forest image user
SNAPSHOTS_DIR=$BASE_FOLDER/s3/$CHAIN_NAME

permission=$(stat -c "%a" "$SNAPSHOTS_DIR")
if ! ((permission & 7)); then
  echo "The snapshots directory is not accessible by everyone to read and write. Adding necessary permissions"
  chmod o+rwx "$SNAPSHOTS_DIR"
else
  echo "Snapshots directory permissions OK"
fi

permission=$(stat -c "%a" "$NEWEST_SNAPSHOT")
if ! ((permission & 4)); then
  echo "Snapshot not readable for everyone. Adding necessary permissions."
  chmod o+r "$NEWEST_SNAPSHOT"
else
  echo "Latest snapshot permissions OK"
fi

# Sync and export is done in a single container to make sure everything is
# properly cleaned up.
COMMANDS=$(cat << HEREDOC
echo "Chain: $CHAIN_NAME"
echo "Snapshot: $NEWEST_SNAPSHOT"
forest --encrypt-keystore false --chain $CHAIN_NAME --import-snapshot /snapshot.car --detach || { echo "failed starting forest daemon"; exit 1; }
timeout $SYNC_TIMEOUT forest-cli --chain $CHAIN_NAME sync wait || { echo "timed-out on forest-cli sync"; exit 1; }
cat forest.err forest.out
forest-cli --chain $CHAIN_NAME snapshot export || { echo "failed to export the snapshot"; exit 1; }
mv ./forest_snapshot* /snapshots/
HEREDOC
)

docker run \
  --name forest-snapshot-upload-node \
  --rm \
  -v "$NEWEST_SNAPSHOT":"/snapshot.car" \
  -v "$SNAPSHOTS_DIR:/snapshots":rshared \
  --entrypoint /bin/bash \
  ghcr.io/chainsafe/forest:"${FOREST_TAG}" \
  -c "$COMMANDS"
