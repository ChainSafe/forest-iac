#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -eux

echo "Current user: $(whoami)"

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

./main.sh
