#!/bin/bash

ENDPOINT="$1"

while read -r file; do
    # Upload the file to the S3 bucket
    aws --profile prod --endpoint "$ENDPOINT" s3 cp "$file" "s3://forest-archive/mainnet/diff/"
done < /mnt/md0/exported/archival/upload_files.txt
