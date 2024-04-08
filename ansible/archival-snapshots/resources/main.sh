#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

FOREST_CLI="/mnt/md0/exported/archival/forest-v0.17.1/forest-cli"
FOREST_TOOL="/mnt/md0/exported/archival/forest-v0.17.1/forest-tool"

CURRENT_SNAPSHOT=$(aws --profile prod --endpoint "$ENDPOINT" s3 ls "s3://forest-archive/mainnet/lite/" | sort | tail -n 1 | awk '{print $NF}')
CURRENT_EPOCH=$(echo "$CURRENT_SNAPSHOT" | awk -F'_' '{gsub(/[^0-9]/, "", $6); print $6}')

echo "Current Height: $CURRENT_EPOCH"

LATEST_EPOCH=$($FOREST_CLI sync status | grep "Height:" | awk '{print $2}')
echo "Latest Height: $LATEST_EPOCH"

while ((LATEST_EPOCH - CURRENT_EPOCH > 30000)); do
   NEW_EPOCH=$((CURRENT_EPOCH + 30000))
   echo "Next Height: $NEW_EPOCH"

   NEW_SNAPSHOT=$($FOREST_CLI snapshot export --tipset "$NEW_EPOCH" --depth 30000 | grep forest |awk -F'[:]' '{print $1}')

   # Generate and upload lite snapshot
   echo "Generating Lite snapshot: $NEW_SNAPSHOT"
   $FOREST_TOOL archive export --epoch "$NEW_EPOCH" --output-path /mnt/md0/exported/archival/lite_snapshots/ "$NEW_SNAPSHOT"
   echo "Lite snapshot generated: $NEW_SNAPSHOT"
   echo "Uploading Lite snapshot: $NEW_SNAPSHOT"
   aws --profile prod --endpoint "$ENDPOINT" s3 cp /mnt/md0/exported/archival/lite_snapshots/"$NEW_SNAPSHOT" "s3://forest-archive/mainnet/lite/"
   echo "Lite snapshot uploaded: $NEW_SNAPSHOT"

   # Generate and upload diff snapshots
   echo "Generating Diff snapshots: $CURRENT_EPOCH - $NEW_EPOCH"
   ./diff_script.sh "$CURRENT_EPOCH" "$CURRENT_SNAPSHOT" "$NEW_SNAPSHOT"
   echo "Diff snapshots generated successfully"
   echo "Uploading Diff snapshots"
   ./upload_diff.sh "$ENDPOINT"
   echo "Diff snapshots uploaded successfully"

   CURRENT_EPOCH=$NEW_EPOCH
done
