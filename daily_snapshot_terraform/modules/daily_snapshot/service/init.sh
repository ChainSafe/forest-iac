#!/bin/bash

dnf install -y docker docker-compose ruby ruby-devel make gcc s3fs-fuse s3cmd
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
    -o url="https://$SNAPSHOT_ENDPOINT" \
    -o allow_other

## Configure s3cmd
s3cmd --dump-config \
    --host="$SNAPSHOT_ENDPOINT" \
    --host-bucket="%(bucket)s.$SNAPSHOT_ENDPOINT" \
    --access_key="$AWS_ACCESS_KEY_ID" \
    --secret_key="$AWS_SECRET_ACCESS_KEY" \
    --multipart-chunk-size-mb=4096 > ~/.s3cfg

## Setup volume
mkdir forest_db
mount -o defaults,nofail,discard,noatime /dev/disk/by-id/scsi-0DO_Volume_snapshot-gen-storage forest_db
chmod 777 forest_db

# Export and upload snapshot
nohup ruby daily_snapshot.rb calibnet > calibnet_log.txt &
nohup ruby daily_snapshot.rb mainnet > mainnet_log.txt &
