#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

GENESIS_TIMESTAMP=1598306400
SECONDS_PER_EPOCH=30

FOREST="/mnt/md0/exported/archival/forest/forest"
FOREST_CLI="/mnt/md0/exported/archival/forest/forest-cli"
FOREST_TOOL="/mnt/md0/exported/archival/forest/forest-tool"

CURRENT_SNAPSHOT=$(aws --profile prod --endpoint "$ENDPOINT" s3 ls "s3://forest-archive/mainnet/lite/" | sort | tail -n 1 | awk '{print $NF}')
CURRENT_EPOCH=$(echo "$CURRENT_SNAPSHOT" | awk -F'_' '{gsub(/[^0-9]/, "", $6); print $6}')
FULL_SNAPSHOTS_DIR=/mnt/md0/exported/archival/snapshots
CURRENT_FULL_SNAPSHOT_PATH="$FULL_SNAPSHOTS_DIR/$CURRENT_SNAPSHOT"
LITE_SNAPSHOT_DIR=/mnt/md0/exported/archival/lite_snapshots

# Check if full snapshots directory exist, if not create
if [ ! -d "$FULL_SNAPSHOTS_DIR" ]; then
    mkdir -p "$FULL_SNAPSHOTS_DIR"
fi

if [ ! -f "$CURRENT_FULL_SNAPSHOT_PATH" ]; then
    echo "Downloading last snapshot: $CURRENT_FULL_SNAPSHOT_PATH"
    aws --profile prod --endpoint "$ENDPOINT" s3 cp "s3://forest-archive/mainnet/lite/$CURRENT_SNAPSHOT" "$CURRENT_FULL_SNAPSHOT_PATH"
    echo "Last snapshot download: $CURRENT_FULL_SNAPSHOT_PATH"
else
    echo "$CURRENT_FULL_SNAPSHOT_PATH snapshot already exists."
fi

echo "Starting forest daemon"
nohup $FOREST --no-gc --config ./config.toml --save-token ./admin_token --rpc-address 127.0.0.1:3456 --metrics-address 127.0.0.1:5000 > forest.log 2>&1 &
FOREST_NODE_PID=$!

sleep 30
echo "Forest process started with PID: $FOREST_NODE_PID"

# Set required env variables
function set_fullnode_api_info {
    ADMIN_TOKEN=$(cat admin_token)
    export FULLNODE_API_INFO="$ADMIN_TOKEN:/ip4/127.0.0.1/tcp/3456/http"
    echo "Using: $FULLNODE_API_INFO"
}
set_fullnode_api_info

echo "Waiting for forest to sync to latest network head"
$FOREST_CLI sync wait

# Get latest epoch using sync status
echo "Current Height: $CURRENT_EPOCH"
LATEST_EPOCH=$($FOREST_CLI sync status | grep "Height:" | awk '{print $2}')
echo "Latest Height: $LATEST_EPOCH"

while ((LATEST_EPOCH - CURRENT_EPOCH > 30000)); do
   set_fullnode_api_info
   NEW_EPOCH=$((CURRENT_EPOCH + 30000))
   echo "Next Height: $NEW_EPOCH"

   # Export full snapshot to generate lite and diff snapshots
   EPOCH_TIMESTAMP=$((GENESIS_TIMESTAMP + NEW_EPOCH*SECONDS_PER_EPOCH))
   DATE=$(date --date=@"$EPOCH_TIMESTAMP" -u -I)
   NEW_SNAPSHOT="forest_snapshot_mainnet_${DATE}_height_${NEW_EPOCH}.forest.car.zst"

   if [ ! -f "$FULL_SNAPSHOTS_DIR/$NEW_SNAPSHOT" ]; then
        echo "Exporting snapshot: $FULL_SNAPSHOTS_DIR/$NEW_SNAPSHOT"
        echo "USING FULLNODE API: $FULLNODE_API_INFO"
        $FOREST_CLI snapshot export --tipset "$NEW_EPOCH" --depth 30000 -o "$FULL_SNAPSHOTS_DIR/$NEW_SNAPSHOT" > export.txt
        echo "Snapshot exported: $FULL_SNAPSHOTS_DIR/$NEW_SNAPSHOT"
    else
        echo "$FULL_SNAPSHOTS_DIR/$NEW_SNAPSHOT already exists."
    fi

   # Generate and upload lite snapshot
   if [ ! -f "$LITE_SNAPSHOT_DIR/$NEW_SNAPSHOT" ]; then
        echo "Generating Lite snapshot: $LITE_SNAPSHOT_DIR/$NEW_SNAPSHOT"
        $FOREST_TOOL archive export --epoch "$NEW_EPOCH" --output-path "$LITE_SNAPSHOT_DIR" "$FULL_SNAPSHOTS_DIR/$NEW_SNAPSHOT"
        echo "Lite snapshot generated: $LITE_SNAPSHOT_DIR/$NEW_SNAPSHOT"
    else
        echo "$NEW_SNAPSHOT lite snapshot already exists."
    fi
   echo "Uploading Lite snapshot: $LITE_SNAPSHOT_DIR/$NEW_SNAPSHOT"
   aws --profile prod --endpoint "$ENDPOINT" s3 cp "$LITE_SNAPSHOT_DIR/$NEW_SNAPSHOT" "s3://forest-archive/mainnet/lite/"
   echo "Lite snapshot uploaded: $LITE_SNAPSHOT_DIR/$NEW_SNAPSHOT"

   # Generate and upload diff snapshots
   if [ ! -f "$CURRENT_FULL_SNAPSHOT_PATH" ]; then
       echo "File does not exist. Exporting..."
       $FOREST_CLI snapshot export --tipset "$CURRENT_EPOCH" --depth 30000 -o "$CURRENT_FULL_SNAPSHOT_PATH"
   else
       echo "$CURRENT_FULL_SNAPSHOT_PATH file exists."
   fi
   echo "Generating Diff snapshots: $CURRENT_EPOCH - $NEW_EPOCH"
   ./diff_script.sh "$CURRENT_EPOCH" "$CURRENT_FULL_SNAPSHOT_PATH" "$FULL_SNAPSHOTS_DIR/$NEW_SNAPSHOT"
   echo "Diff snapshots generated successfully"
   echo "Uploading Diff snapshots"
   ./upload_diff.sh "$ENDPOINT"
   echo "Diff snapshots uploaded successfully"

   CURRENT_EPOCH=$NEW_EPOCH
done

kill -KILL $FOREST_NODE_PID
