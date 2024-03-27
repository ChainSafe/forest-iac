#!/bin/env bash

set -euxo pipefail

FOREST=~/forest-v0.14.0/forest-tool

EPOCH_START="$1"
shift
DIFF_STEP=3000
DIFF_COUNT=10
GENESIS_TIMESTAMP=1598306400
SECONDS_PER_EPOCH=30

for i in $(seq 1 $DIFF_COUNT); do
    EPOCH=$((EPOCH_START+DIFF_STEP*i))
    EPOCH_TIMESTAMP=$((GENESIS_TIMESTAMP + EPOCH*SECONDS_PER_EPOCH))
    DATE=$(date --date=@"$EPOCH_TIMESTAMP" -u -I)
    FILE="diff_snapshots/forest_diff_mainnet_${DATE}_height_$((EPOCH-DIFF_STEP))+$DIFF_STEP.forest.car.zst"
    if ! test -f "$FILE"; then
        "$FOREST" archive export --depth "$DIFF_STEP" --epoch "$EPOCH" --diff $((EPOCH-DIFF_STEP)) --diff-depth 900 --output-path "$FILE" "$@"
    else
        echo "Skipping $FILE"
    fi
done
