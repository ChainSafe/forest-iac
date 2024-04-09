#!/bin/bash

LITE_SNAPSHOT_DIR="/mnt/md0/exported/archival/lite_snapshots"
DIFF_SNAPSHOT_DIR="/mnt/md0/exported/archival/diff_snapshots"

if [ ! -d "$LITE_SNAPSHOT_DIR" ]; then
    mkdir -p "$LITE_SNAPSHOT_DIR"
    echo "Created $LITE_SNAPSHOT_DIR"
else
    echo "$LITE_SNAPSHOT_DIR exists"
fi

if [ ! -d "$DIFF_SNAPSHOT_DIR" ]; then
    mkdir -p "$DIFF_SNAPSHOT_DIR"
    echo "Created $DIFF_SNAPSHOT_DIR"
else
    echo "$DIFF_SNAPSHOT_DIR exists"
fi

# Check if the main.sh script executed successfully
if ./main.sh; then
    # If successful, call notify.rb with "success"
    ruby notify.rb "success"
else
    # If failed, call notify.rb with "failure"
    ruby notify.rb "failure"
fi
