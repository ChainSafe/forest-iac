#!/bin/env bash

set -euxo pipefail

FOREST=/mnt/md0/exported/archival/forest-v0.17.2/forest-tool
UPLOADED_DIFFS=/mnt/md0/exported/archival/uploaded-diff-snaps.txt
UPLOAD_QUEUE="/mnt/md0/exported/archival/upload_files.txt"

EPOCH_START="$1"
shift
DIFF_STEP=3000
DIFF_COUNT=10
GENESIS_TIMESTAMP=1598306400
SECONDS_PER_EPOCH=30

# Clear Upload List
if [ -f "$UPLOAD_QUEUE" ]; then
    # Clear the contents of the file
    true > "$UPLOAD_QUEUE"
fi


aws --profile prod --endpoint "$ENDPOINT" s3 ls "s3://forest-archive/mainnet/diff/" > "$UPLOADED_DIFFS"

for i in $(seq 1 $DIFF_COUNT); do
    EPOCH=$((EPOCH_START+DIFF_STEP*i))
    EPOCH_TIMESTAMP=$((GENESIS_TIMESTAMP + EPOCH*SECONDS_PER_EPOCH))
    DATE=$(date --date=@"$EPOCH_TIMESTAMP" -u -I)
    FILE_NAME="forest_diff_mainnet_${DATE}_height_$((EPOCH-DIFF_STEP))+$DIFF_STEP.forest.car.zst"
    FILE="/mnt/md0/exported/archival/diff_snapshots/$FILE_NAME"
    if ! grep -q "$FILE_NAME" "$UPLOADED_DIFFS"; then
        if ! test -f "$FILE"; then
            # Export diff snapshot
            "$FOREST" archive export --depth "$DIFF_STEP" --epoch "$EPOCH" --diff $((EPOCH-DIFF_STEP)) --diff-depth 900 --output-path "$FILE" "$@"
        fi
        # Add exported diff snapshot to upload queue
        echo "$FILE" >> "$UPLOAD_QUEUE"
    else
        echo "Skipping $FILE"
    fi
done
