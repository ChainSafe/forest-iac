#!/bin/bash
# Uploads all the snapshots to the S3 bucket
# Usage: ./upload_data.sh <endpoint>

set -eu

# Get endpoint from the argument
if [ $# -eq 0 ]; then
    echo "No endpoint provided"
    exit 1
fi

ENDPOINT="$1"

function upload_file() {
    echo "Uploading $1 to $2"
    aws --endpoint "$ENDPOINT" s3 cp "$1" s3://"$2"
}

shopt -s globstar nullglob
for file in forest_diff*; do
    upload_file "$file" calibnet/diff/
done

for file in forest_snapshot*; do
    upload_file "$file" calibnet/lite/
done
