#!/bin/bash

ENDPOINT="$1"

# list files to upload
ls diff_snapshots/ > upload_files.txt

while read -r file; do
    # Upload the file to the S3 bucket
    aws --profile prod --endpoint "$ENDPOINT" s3 cp diff_snapshots/"$file" "s3://forest-archive/mainnet/diff/"
done < upload_files.txt

# Remove uploaded diff snapshots 
rm diff_snapshots/* -rf
