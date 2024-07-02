#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -eux

# Initialize snapshots directory
LITE_SNAPSHOT_DIR="/mnt/md0/exported/archival/lite_snapshots"
DIFF_SNAPSHOT_DIR="/mnt/md0/exported/archival/diff_snapshots"
FULL_SNAPSHOTS_DIR=/mnt/md0/exported/archival/snapshots

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

if [ ! -d "$FULL_SNAPSHOTS_DIR" ]; then
    mkdir -p "$FULL_SNAPSHOTS_DIR"
    echo "Created $FULL_SNAPSHOTS_DIR"
else
    echo "$FULL_SNAPSHOTS_DIR exists"
fi

# Trigger main script
./main.sh

EXIT_STATUS=$?

# Notify on slack channel
if [ "$EXIT_STATUS" -eq 0 ]; then
    echo "Script executed successfully"
    ruby notify.rb success
else
    echo "Script execution failed"
    ruby notify.rb failure
fi

exit "$EXIT_STATUS"
