#!/bin/bash

set -e

## Ensure watchtower is running
docker stop watchtower 2> /dev/null || true
docker wait watchtower 2> /dev/null || true
docker run --rm \
    --detach \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --name watchtower \
    containrrr/watchtower \
    --label-enable --include-stopped --revive-stopped --stop-timeout 120s --interval 600

# Clean volumes
rm -rf "${FOREST_TARGET_DATA:?}"/*
rm -rf "${FOREST_TARGET_SCRIPTS:?}"/*
rm -rf "${FOREST_TARGET_RUBY_COMMON:?}"/*

# We need it to access the DATA_DIR regardless of the user.
chmod 0777 "${FOREST_TARGET_DATA:?}"

# Copy all relevant scripts
cp -R /chainsafe/* "$FOREST_TARGET_SCRIPTS"
cp -R /chainsafe/ruby_common/* "$FOREST_TARGET_RUBY_COMMON"

# Export and upload snapshot
ruby sync_check_process.rb
