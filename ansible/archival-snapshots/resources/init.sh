#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

ENDPOINT="$1"
FOREST_CLI="/home/archie/forest-v0.16.3/forest-cli"
FOREST_TOOL="/home/archie/forest-v0.16.3/forest-tool"

# Setting DEBIAN_FRONTEND to ensure non-interactive operations for APT
export DEBIAN_FRONTEND=noninteractive

CURRENT_SNAPSHOT=$(aws --profile prod --endpoint "$ENDPOINT" s3 ls "s3://forest-archive/mainnet/lite/" | sort | tail -n 1 | awk '{print $NF}')
CURRENT_EPOCH=$(echo "$CURRENT_SNAPSHOT" | awk -F'_' '{gsub(/[^0-9]/, "", $6); print $6}')

echo "$CURRENT_EPOCH"

LATEST_EPOCH=$($FOREST_CLI sync status | grep "Height:" | awk '{print $2}')
echo "$LATEST_EPOCH"

while ((LATEST_EPOCH - CURRENT_EPOCH > 30000)); do
   NEW_EPOCH=$((CURRENT_EPOCH + 30000))
   NEW_SNAPSHOT=$($FOREST_CLI snapshot export --tipset "$NEW_EPOCH" --depth 30000 | grep forest |awk -F'[:]' '{print $1}')

   # Generate and upload lite snapshot
   $FOREST_TOOL archive export --epoch "$NEW_EPOCH" --output-path ./lite_snapshots/ "$NEW_SNAPSHOT"
   aws --profile prod --endpoint "$ENDPOINT" s3 cp ./lite_snapshots/"$NEW_SNAPSHOT" "s3://forest-archive/mainnet/lite/"

   # Generate and upload diff snapshots
   ./diff_script.sh "$CURRENT_EPOCH" "$CURRENT_SNAPSHOT" "$NEW_SNAPSHOT"
   ./upload_diff.sh "$CURRENT_EPOCH"

   CURRENT_EPOCH=$NEW_EPOCH
done

# Send notification on slack
ruby notify.rb "$CURRENT_EPOCH"
