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
chmod -R +rw "$BASE_FOLDER/s3/$CHAIN_NAME"

# Sync and export is done in a single container to make sure everything is
# properly cleaned up.
COMMANDS=$(cat << HEREDOC
echo "Chain: $CHAIN_NAME"
echo "Snapshot: $NEWEST_SNAPSHOT"
forest --encrypt-keystore false --chain $CHAIN_NAME --import-snapshot $NEWEST_SNAPSHOT --detach || { echo "failed starting forest daemon"; exit 1; }
timeout $SYNC_TIMEOUT forest-cli sync wait || { echo "timed-out on forest-cli sync"; exit 1; }
cat forest.err forest.out
forest-cli snapshot export || { echo "failed to export the snapshot"; exit 1; }
mv ./forest_snapshot* $BASE_FOLDER/s3/$CHAIN_NAME/
HEREDOC
)

docker run \
  --name forest-snapshot-upload-node \
  --rm \
  -v "$BASE_FOLDER":"$BASE_FOLDER":rshared \
  --entrypoint /bin/bash \
  ghcr.io/chainsafe/forest:"${FOREST_TAG}" \
  -c "$COMMANDS"
