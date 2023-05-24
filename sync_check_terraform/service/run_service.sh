#!/bin/bash

set -e

## Source forest env variables
source ~/.forest_env

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

# Export and upload snapshot
ruby sync_check_process.rb
