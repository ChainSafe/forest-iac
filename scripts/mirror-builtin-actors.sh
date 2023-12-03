#!/bin/bash

# This script mirrors all releases of Filecoin's builtin-actors that have been updated in the past two weeks.
# It performs the following operations:
# - Downloads release assets from GitHub.
# - Compares these assets with the existing ones in an S3 bucket.
# - Uploads new or updated assets to the S3 bucket.
# - Sends an alert to Slack if any uploads fail.

set -eo pipefail

export DEBIAN_FRONTEND=noninteractive

BASE_FOLDER="$(pwd)/releases/actors"
API_URL="https://api.github.com/repos/filecoin-project/builtin-actors/releases"
FAILED_LOG="$(pwd)/failed_uploads.log"

 : 'Create base directory and log file'
mkdir -p "$BASE_FOLDER"

: 'Calculate the date two weeks ago in Unix timestamp format'
TWO_WEEK_AGO=$(date -d '2 week ago' +%s)

: 'Fetch all releases and create directories for those published in the last week'
curl -sS $API_URL | jq -c '.[]' | while read -r release; do
    TAG_NAME=$(echo "$release" | jq -r '.tag_name')
    PUBLISHED_DATE=$(echo "$release" | jq -r '.published_at')

    # Convert PUBLISHED_DATE to seconds since the epoch for comparison
    PUBLISHED_DATE_SEC=$(date -d "$PUBLISHED_DATE" +%s)

    # Check if PUBLISHED_DATE_SEC is equal to or more recent than TWO_WEEK_AGO
    if [[ "$PUBLISHED_DATE_SEC" -ge "$TWO_WEEK_AGO" ]]; then
        mkdir -p "$BASE_FOLDER/$TAG_NAME"
    fi
done

: 'Initialize array for tracking failed uploads'
declare -a failed_uploads

: 'Function to send Slack alert with failed uploads'
send_slack_alert_with_failed() {
    local failure_count=${#failed_uploads[@]}
    local message="🚨 Fileoin Actors Mirror Update:\n🔥 Failed Uploads: $failure_count"

    curl -F file=@"$FAILED_LOG" -F "initial_comment=$message" -F channels="$SLACK_CHANNEL" \
         -H "Authorization: Bearer $SLACK_API_TOKEN" \
         https://slack.com/api/files.upload
}

: 'Loop through each version directory to process and upload assets'
while IFS= read -r version_dir; do
    TAG_NAME=${version_dir#"$BASE_FOLDER"/}
    VERSION_DIR="$version_dir"
    if [ -d "$VERSION_DIR" ]; then
        echo "Entering directory: $VERSION_DIR"

        release=$(curl -sS $API_URL | jq -c --arg TAG_NAME "$TAG_NAME" '.[] | select(.tag_name==$TAG_NAME)')
        ASSETS=$(echo "$release" | jq -c '.assets[]')

        : 'Download assets for this release'
        pushd "$VERSION_DIR" > /dev/null
        echo "Processing assets for $TAG_NAME..."
        if [ -z "$ASSETS" ]; then
            echo "No assets found for $TAG_NAME."
        else
            echo "$ASSETS" | while IFS= read -r asset; do
                DOWNLOAD_URL=$(echo "$asset" | jq -r '.browser_download_url')
                FILE_NAME=$(echo "$asset" | jq -r '.name')

                echo "Checking asset: $FILE_NAME"
                if [ ! -f "$FILE_NAME" ]; then
                    echo "Downloading $FILE_NAME..."
                    wget -q "$DOWNLOAD_URL" -O "$FILE_NAME" || echo "Failed to download $FILE_NAME"
                fi

                : 'Compare the downloaded file with the one in S3; upload if different'
                echo "Checking $FILE_NAME against S3 version..."
                TEMP_S3_DIR=$(mktemp -d)
                s3cmd get --no-progress "s3://$BUCKET_NAME/$TAG_NAME/$FILE_NAME" "$TEMP_S3_DIR/$FILE_NAME" || true

                if cmp --silent "$FILE_NAME" "$TEMP_S3_DIR/$FILE_NAME"; then
                    echo "$FILE_NAME is the same in S3, skipping..."
                    rm "$FILE_NAME" "$TEMP_S3_DIR/$FILE_NAME"
                else
                    echo "Local $FILE_NAME is different. Uploading to S3..."
                    if s3cmd --acl-public put "$FILE_NAME" "s3://$BUCKET_NAME/$TAG_NAME/$FILE_NAME"; then
                        echo "Uploaded $FILE_NAME to s3://$BUCKET_NAME/$TAG_NAME/$FILE_NAME"
                        rm "$FILE_NAME" "$TEMP_S3_DIR/$FILE_NAME"
                    else
                        echo "Failed to upload $FILE_NAME. Logging to $FAILED_LOG"
                        echo "$TAG_NAME/$FILE_NAME" >> "$FAILED_LOG"
                        failed_uploads+=("$TAG_NAME/$FILE_NAME")
                        rm "$FILE_NAME" "$TEMP_S3_DIR/$FILE_NAME"
                    fi
                fi
                rm -rf "$TEMP_S3_DIR"
            done
        fi
        popd > /dev/null
    fi
done < <(find "$BASE_FOLDER" -mindepth 1 -type d)

: 'Send summary alert only if there were failed uploads'
if [ ${#failed_uploads[@]} -ne 0 ]; then
    send_slack_alert_with_failed
else
    echo "No new mirroring failures"
fi
