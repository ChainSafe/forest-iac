#!/bin/bash
# This script resets everything and executes the sync check process

# Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

## Start docker daemon
systemctl start docker

# Kill all relevant containers
docker container rm --force watchtower 2> /dev/null || true
docker container rm --force forest-calibnet 2> /dev/null || true
docker container rm --force forest-mainnet 2> /dev/null || true
docker container rm --force forest-tester 2> /dev/null || true

# Clean volumes
rm -rf /var/lib/docker/volumes/forest-data/_data/*
rm -rf /var/lib/docker/volumes/sync-check/_data/*
rm -rf /var/lib/docker/volumes/ruby-common/_data/*

## Ensure watchtower is running
docker stop watchtower 2> /dev/null || true
docker wait watchtower 2> /dev/null || true
docker run \
    --detach \
    --restart unless-stopped \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --name watchtower \
    containrrr/watchtower \
    --label-enable --include-stopped --revive-stopped --stop-timeout 120s --interval 600

## Setup volume
docker volume create --name=forest-data
docker volume create --name=sync-check
docker volume create --name=ruby-common

## We need it to access the DATA_DIR regardless of the user.
chmod 0777 /var/lib/docker/volumes/forest-data/_data

## Copy all relevant scripts
cp -R /root/* /var/lib/docker/volumes/sync-check/_data/
cp -R /root/ruby_common/* /var/lib/docker/volumes/ruby-common/_data/

# Export and upload snapshot
ruby sync_check_process.rb
