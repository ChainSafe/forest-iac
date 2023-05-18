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
rm -rf /var/lib/docker/volumes/forest-data/_data/*
rm -rf /var/lib/docker/volumes/sync-check/_data/*
rm -rf /var/lib/docker/volumes/ruby-common/_data/*

# We need it to access the DATA_DIR regardless of the user.
chmod 0777 /var/lib/docker/volumes/forest-data/_data

# Copy all relevant scripts
cp -R /root/* /var/lib/docker/volumes/sync-check/_data/
cp -R /root/ruby_common/* /var/lib/docker/volumes/ruby-common/_data/

# Export and upload snapshot
ruby sync_check_process.rb
