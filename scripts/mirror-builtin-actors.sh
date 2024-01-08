#!/bin/bash

# This script mirrors all releases of Filecoin's builtin-actors that have been updated in the past three years,
# It respects GitHub API rate limits and paginates requests.
# It performs the following operations:
# - Downloads release assets from GitHub.
# - Compares these assets with the existing ones in an S3 bucket.
# - Uploads new or updated assets to the S3 bucket.
# - Sends an alert to Slack if any uploads fail.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

BASE_FOLDER="$(pwd)/releases/actors"
API_URL="https://api.github.com/repos/filecoin-project/builtin-actors/releases"
FAILED_LOG="$(pwd)/failed_uploads.log"
THREE_YEARS_AGO=$(date --date='3 years ago' +%s)

mkdir --parents "$BASE_FOLDER"

# Function to extract the next page URL from GitHub API response headers for pagination.
get_next_page_url() {
    local headers="$1"
    echo "$headers" | grep --only-matching --perl-regexp '<\K([^>]+)(?=>; rel="next")' || echo ""
}

# Function to send Slack alert with failed uploads
send_slack_alert_with_failed() {
    local failure_count=${#failed_uploads[@]}
    local message="🚨 Filecoin Actors Mirror Update:\n🔥 Failed Uploads: $failure_count"

    # Attach the log file with failed uploads
    curl --form file=@"$FAILED_LOG" --form "initial_comment=$message" --form channels="$SLACK_CHANNEL" \
         --header "Authorization: Bearer $SLACK_API_TOKEN" \
         https://slack.com/api/files.upload
}

# Function to fetch and process releases
fetch_and_process_releases() {
    local page_url="$API_URL"

    while [[ -n $page_url ]]; do
        response=$(curl --silent --head "$page_url")
        body=$(curl --silent "$page_url")
        next_page_url=$(get_next_page_url "$response")

        echo "$body" | jq --compact-output '.[]' | while read -r release; do
            TAG_NAME=$(echo "$release" | jq --raw-output '.tag_name') || echo "Error: $release, could not get tag name"
            PUBLISHED_DATE=$(echo "$release" | jq --raw-output '.published_at')
            PUBLISHED_DATE_SEC=$(date --date="$PUBLISHED_DATE" +%s)

            if echo "$TAG_NAME" | grep --extended-regexp '^v[0-9]+\.[0-9]+\.[0-9]+.*$' && [[ "$PUBLISHED_DATE_SEC" -ge "$THREE_YEARS_AGO" ]]; then
                mkdir --parents "$BASE_FOLDER/$TAG_NAME"
            fi
        done

        page_url="$next_page_url"
    done
}

fetch_and_process_releases

declare -a failed_uploads
failed_uploads=()

: 'Loop through each version directory to process and upload assets'
while IFS= read -r version_dir; do
    TAG_NAME=${version_dir#"$BASE_FOLDER"/}
    VERSION_DIR="$version_dir"
    if [ -d "$VERSION_DIR" ]; then
        echo "Entering directory: $VERSION_DIR"

        tag_url="$API_URL/tags/$TAG_NAME"
        release=$(curl --silent "$tag_url")

        # Check if the assets array is not null
        if [[ $(echo "$release" | jq '.assets') != "null" ]]; then
            ASSETS=$(echo "$release" | jq --compact-output '.assets[]')

            pushd "$VERSION_DIR" > /dev/null
            echo "Processing assets for $TAG_NAME..."

            echo "$ASSETS" | while IFS= read -r asset; do
                DOWNLOAD_URL=$(echo "$asset" | jq --raw-output '.browser_download_url')
                FILE_NAME=$(echo "$asset" | jq --raw-output '.name')

                echo "Checking asset: $FILE_NAME"
                if [ ! -f "$FILE_NAME" ]; then
                    echo "Downloading $FILE_NAME..."
                    curl --silent --output "$FILE_NAME" "$DOWNLOAD_URL" || echo "Failed to download $FILE_NAME"
                fi

                echo "Checking $FILE_NAME against S3 version..."
                TEMP_S3_DIR=$(mktemp --directory)
                s3cmd get --no-progress "s3://$BUCKET_NAME/$TAG_NAME/$FILE_NAME" "$TEMP_S3_DIR/$FILE_NAME" || true

                if cmp --silent "$FILE_NAME" "$TEMP_S3_DIR/$FILE_NAME"; then
                    echo "$FILE_NAME is the same in S3, skipping..."
                else
                    echo "Local $FILE_NAME is different. Uploading to S3..."
                    if s3cmd --acl-public put "$FILE_NAME" "s3://$BUCKET_NAME/$TAG_NAME/$FILE_NAME"; then
                        echo "Uploaded $FILE_NAME to s3://$BUCKET_NAME/$TAG_NAME/$FILE_NAME"
                    else
                        echo "Failed to upload $FILE_NAME. Logging to $FAILED_LOG"
                        echo "$TAG_NAME/$FILE_NAME" >> "$FAILED_LOG"
                        failed_uploads+=("$TAG_NAME/$FILE_NAME")
                    fi
                fi
                rm --recursive --force "$TEMP_S3_DIR"
                rm --force "$FILE_NAME"
            done
            popd > /dev/null
        else
            echo "No assets found for $TAG_NAME."
        fi
    fi
done < <(find "$BASE_FOLDER" -mindepth 1 -type d)

: 'Send summary alert only if there were failed uploads'
if [ ${#failed_uploads[@]} -ne 0 ]; then
    send_slack_alert_with_failed
else
    echo "No new mirroring failures"
fi
