#!/bin/bash

# This script mirrors all releases of Filecoin's builtin-actors that have been updated in the past two years,
# It respects GitHub API rate limits and paginates requests.
# It performs the following operations:
# - Downloads release assets from GitHub.
# - Compares these assets with the existing ones in an S3 bucket.
# - Uploads new or updated assets to the S3 bucket.
# - Sends an alert to Slack if any uploads fail.

set -eo pipefail

export DEBIAN_FRONTEND=noninteractive

BASE_FOLDER="$(pwd)/releases/actors"
API_URL="https://api.github.com/repos/filecoin-project/builtin-actors/releases"
LIST_FILE="$(pwd)/release_list_for_review.txt"
FAILED_LOG="$(pwd)/failed_uploads.log"
TWO_YEARS_AGO=$(date -d '2 years ago' +%s)

mkdir -p "$BASE_FOLDER"
true > "$LIST_FILE"

# Function to extract the next page URL from GitHub API response headers for pagination.
get_next_page_url() {
    local headers="$1"
    echo "$headers" | grep -oP '<\K([^>]+)(?=>; rel="next")' || echo ""
}

# Function to fetch and process releases
fetch_and_process_releases() {
    local api_url="$1"
    local page_url="$api_url"

    while [[ -n $page_url ]]; do
        response=$(curl -s -I "$page_url")
        body=$(curl -s "$page_url")
        next_page_url=$(get_next_page_url "$response")

        echo "$body" | jq -c '.[]' | while read -r release; do
            TAG_NAME=$(echo "$release" | jq -r '.tag_name')
            PUBLISHED_DATE=$(echo "$release" | jq -r '.published_at')
            PUBLISHED_DATE_SEC=$(date -d "$PUBLISHED_DATE" +%s)

            if echo "$TAG_NAME" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+.*$' && [[ "$PUBLISHED_DATE_SEC" -ge "$TWO_YEARS_AGO" ]]; then
                mkdir -p "$BASE_FOLDER/$TAG_NAME"
                echo "$TAG_NAME" >> "$LIST_FILE"
            fi
        done

        page_url="$next_page_url"
    done
}

fetch_and_process_releases "$API_URL"

declare -a failed_uploads

: 'Loop through each version directory to process and upload assets'
while IFS= read -r version_dir; do
    TAG_NAME=${version_dir#"$BASE_FOLDER"/}
    VERSION_DIR="$version_dir"
    if [ -d "$VERSION_DIR" ]; then
        echo "Entering directory: $VERSION_DIR"

        tag_url="$API_URL/tags/$TAG_NAME"
        release=$(curl -sS "$tag_url")

        # Check if the assets array is not null
        if [[ $(echo "$release" | jq '.assets') != "null" ]]; then
            ASSETS=$(echo "$release" | jq -c '.assets[]')

            pushd "$VERSION_DIR" > /dev/null
            echo "Processing assets for $TAG_NAME..."

            echo "$ASSETS" | while IFS= read -r asset; do
                DOWNLOAD_URL=$(echo "$asset" | jq -r '.browser_download_url')
                FILE_NAME=$(echo "$asset" | jq -r '.name')

                echo "Checking asset: $FILE_NAME"
                if [ ! -f "$FILE_NAME" ]; then
                    echo "Downloading $FILE_NAME..."
                    wget -q "$DOWNLOAD_URL" -O "$FILE_NAME" || echo "Failed to download $FILE_NAME"
                fi

                echo "Checking $FILE_NAME against S3 version..."
                TEMP_S3_DIR=$(mktemp -d)
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
                rm -rf "$TEMP_S3_DIR"
                rm -f "$FILE_NAME"
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
