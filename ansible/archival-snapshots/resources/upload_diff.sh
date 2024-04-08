#!/bin/bash

ENDPOINT="$1"

# list files to upload
ls /mnt/md0/exported/archival/diff_snapshots/ > /mnt/md0/exported/archival/upload_files.txt

while read -r file; do
    # Upload the file to the S3 bucket
    aws --profile prod --endpoint "$ENDPOINT" s3 cp /mnt/md0/exported/archival/diff_snapshots/"$file" "s3://forest-archive/mainnet/diff/"
done < /mnt/md0/exported/archival/upload_files.txt

# Remove uploaded diff snapshots
rm /mnt/md0/exported/archival/diff_snapshots/* -rf
