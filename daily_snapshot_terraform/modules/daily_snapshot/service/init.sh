#!/bin/bash

dnf install -y docker docker-compose ruby ruby-devel make gcc s3fs-fuse
gem install docker-api slack-ruby-client activesupport

systemctl start docker

export BASE_FOLDER=/root/
export FOREST_TAG=latest

S3_FOLDER=$BASE_FOLDER/s3

# 1. Setup s3fs to get the snapshots.
# 2. Make sure an instance of watchtower is running.
# 3. Run Ruby script for exporting and uploading a new snapshot
#    if there isn't one for today already.

## Setup s3
mkdir --parents "$S3_FOLDER"

s3fs "$SNAPSHOT_BUCKET" "$S3_FOLDER" \
    -o default_acl=public-read \
    -o url="$SNAPSHOT_ENDPOINT" \
    -o allow_other

# Export and upload snapshot
ruby daily_snapshot.rb "$1"
