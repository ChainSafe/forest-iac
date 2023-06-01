#!/bin/bash

# The .env file contains environment variables that we want access to.
set -o allexport
# Trust that the `.env` exists in the CWD during the script execution.
# shellcheck disable=SC1091
source .env
set +o allexport

error=0

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
    exit 1
fi

# Kill all relevant containers
docker container rm --force forest-sync-check 2> /dev/null || true
docker container rm --force watchtower 2> /dev/null || true
docker container rm --force forest-calibnet 2> /dev/null || true
docker container rm --force forest-mainnet 2> /dev/null || true
docker container rm --force forest-tester 2> /dev/null || true

docker run \
    --name forest-sync-check \
    --network host \
    --env-file .env \
    --detach \
    --restart unless-stopped \
    --label com.centurylinklabs.watchtower.enable=true \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume forest-data:"$FOREST_TARGET_DATA" \
    --volume sync-check:"$FOREST_TARGET_SCRIPTS" \
    --volume ruby-common:"$FOREST_TARGET_RUBY_COMMON" \
    ghcr.io/chainsafe/sync-check:latest
