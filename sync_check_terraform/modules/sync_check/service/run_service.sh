#!/bin/bash

set -e

# Check if an environment variable is set. If it isn't, set error=1.
check_env () {
    A="                            ";
    echo -n "${A:0:-${#1}} $1: "
    if [[ -z "${!1}" ]]; then
        echo "❌"
        error=1
    else
        echo "✅"
    fi
}

# Check that the environment variables in the .env file have been defined.
check_env "FOREST_SLACK_API_TOKEN"
check_env "FOREST_SLACK_NOTIF_CHANNEL"
check_env "FOREST_TAG"
check_env "FOREST_TARGET_SCRIPTS"
check_env "FOREST_TARGET_DATA"
check_env "FOREST_TARGET_RUBY_COMMON"

if [ "$error" -ne "0" ]; then
    echo "Please set the required environment variables and try again."
    echo "FOREST_SLACK_API_TOKEN=$FOREST_SLACK_API_TOKEN"
    echo "FOREST_SLACK_NOTIF_CHANNEL=$FOREST_SLACK_NOTIF_CHANNEL"
    echo "FOREST_TAG=$FOREST_TAG"
    echo "FOREST_TARGET_SCRIPTS=$FOREST_TARGET_SCRIPTS"
    echo "FOREST_TARGET_DATA=$FOREST_TARGET_DATA"
    echo "FOREST_TARGET_RUBY_COMMON=$FOREST_TARGET_RUBY_COMMON"
    exit 1
fi

## Start docker daemon
systemctl start docker

# Kill all relevant containers
docker container rm --force watchtower 2> /dev/null || true
docker container rm --force forest-calibnet 2> /dev/null || true
docker container rm --force forest-mainnet 2> /dev/null || true
docker container rm --force forest-tester 2> /dev/null || true

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
