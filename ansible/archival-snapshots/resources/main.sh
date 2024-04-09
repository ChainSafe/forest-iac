#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

FOREST_CLI="/mnt/md0/exported/archival/forest-v0.17.1/forest-cli"
FOREST_TOOL="/mnt/md0/exported/archival/forest-v0.17.1/forest-tool"

CURRENT_SNAPSHOT=$(aws --profile prod --endpoint "$ENDPOINT" s3 ls "s3://forest-archive/mainnet/lite/" | sort | tail -n 1 | awk '{print $NF}')
CURRENT_EPOCH=$(echo "$CURRENT_SNAPSHOT" | awk -F'_' '{gsub(/[^0-9]/, "", $6); print $6}')
FULL_SNAPSHOTS_DIR=/mnt/md0/exported/snapshots
CURRENT_FULL_SNAPSHOT_PATH="$FULL_SNAPSHOTS_DIR/$CURRENT_SNAPSHOT"
LITE_SNAPSHOT_DIR=/mnt/md0/exported/archival/lite_snapshots

# Check if full snapshots directory exist, if not create
if [ ! -d "$FULL_SNAPSHOTS_DIR" ]; then
    mkdir -p "$FULL_SNAPSHOTS_DIR"
fi

# Get latest epoch using sync status
echo "Current Height: $CURRENT_EPOCH"
LATEST_EPOCH=$($FOREST_CLI sync status | grep "Height:" | awk '{print $2}')
echo "Latest Height: $LATEST_EPOCH"

while ((LATEST_EPOCH - CURRENT_EPOCH > 30000)); do
   NEW_EPOCH=$((CURRENT_EPOCH + 30000))
   echo "Next Height: $NEW_EPOCH"

   # Export full snapshot to generate lite and diff snapshots
   NEW_SNAPSHOT=$($FOREST_CLI snapshot export --tipset "$NEW_EPOCH" --depth 30000 | grep forest |awk -F'[:]' '{print $1}')

   # Generate and upload lite snapshot
   if [ ! -f "$LITE_SNAPSHOT_DIR/$NEW_SNAPSHOT" ]; then
        echo "Generating Lite snapshot: $NEW_SNAPSHOT"
        $FOREST_TOOL archive export --epoch "$NEW_EPOCH" --output-path "$LITE_SNAPSHOT_DIR" "$NEW_SNAPSHOT"
        echo "Lite snapshot generated: $NEW_SNAPSHOT"
    else
        echo "$NEW_SNAPSHOT lite snapshot already exists."
    fi
   echo "Uploading Lite snapshot: $NEW_SNAPSHOT"
   aws --profile prod --endpoint "$ENDPOINT" s3 cp "$LITE_SNAPSHOT_DIR/$NEW_SNAPSHOT" "s3://forest-archive/mainnet/lite/"
   echo "Lite snapshot uploaded: $NEW_SNAPSHOT"

   # Generate and upload diff snapshots
   if [ ! -f "$CURRENT_SNAPSHOT_FULL_PATH" ]; then
       echo "File does not exist. Exporting..."
       $FOREST_CLI snapshot export --tipset "$CURRENT_EPOCH" --depth 30000 -o "$CURRENT_SNAPSHOT_FULL_PATH"
   else
       echo "$CURRENT_SNAPSHOT_FULL_PATH file exists."
   fi
   echo "Generating Diff snapshots: $CURRENT_EPOCH - $NEW_EPOCH"
   ./diff_script.sh "$CURRENT_EPOCH" "$CURRENT_FULL_SNAPSHOT_PATH" "$NEW_SNAPSHOT"
   echo "Diff snapshots generated successfully"
   echo "Uploading Diff snapshots"
   ./upload_diff.sh "$ENDPOINT"
   echo "Diff snapshots uploaded successfully"

   CURRENT_EPOCH=$NEW_EPOCH
   mv "$NEW_SNAPSHOT" "$FULL_SNAPSHOTS_DIR"
done
