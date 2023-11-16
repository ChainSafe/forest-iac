#!/bin/bash

# This script automates the process of mirroring the latest releases of FILEcoin's builtin-actors.
# It downloads the latest release assets from GitHub and compares them with the existing ones in an S3 bucket.
# If there are new or updated assets, the script uploads them to the bucket and send alerts to Slack.

set -eo pipefail

export DEBIAN_FRONTEND=noninteractive

RELEASE_FOLDER="releases/actors"

# Move to the base folder
mkdir -p "$RELEASE_FOLDER"
cd "$RELEASE_FOLDER"

# Set the GitHub API URL for the latest release
API_URL="https://api.github.com/repos/filecoin-project/builtin-actors/releases/latest"

# Use curl to fetch the latest release data
ASSETS=$(curl -sS $API_URL | jq -c '.assets[]')

# Check if assets are available
if [ -z "$ASSETS" ]; then
    echo "No assets found for the latest release."
    exit 1
fi

# Download ASSETS from GitHub
echo "$ASSETS" | while read -r asset; do
    DOWNLOAD_URL=$(echo "$asset" | jq -r '.browser_download_url')
    FILE_NAME=$(echo "$asset" | jq -r '.name')

    if [ ! -f "$FILE_NAME" ]; then
        echo "Downloading $FILE_NAME..."
        wget -q "$DOWNLOAD_URL" -O "$FILE_NAME"
    fi
done

# Initialize arrays for tracking uploads
declare -a successful_uploads
declare -a failed_uploads

# Function to send Slack alert with summary
send_slack_alert_with_summary() {
    local success_list="${successful_uploads[*]}"
    local failure_list="${failed_uploads[*]}"
    local message="$ENVIROMENT builtin-actors assets upload summary:\n✅ Successful: $success_list\n🔥 Failed: $failure_list"

    curl -X POST -H 'Content-type: application/json' -H "Authorization: Bearer $SLACK_API_TOKEN" \
    --data "{\"channel\":\"$SLACK_CHANNEL\",\"text\":\"${message}\"}" \
    https://slack.com/api/chat.postMessage
}

# Loop through all files in the current directory
for file in *; do
    if [ -f "$file" ]; then
        echo "Checking $file against S3 version..."

        # Create a temporary directory for the S3 download
        TEMP_S3_DIR=$(mktemp -d)

        # Download the file from S3 to the temporary location
        s3cmd get --no-progress "s3://$BUCKET_NAME/$file" "$TEMP_S3_DIR/$file" || true

        # Compare the local file with the downloaded file
        if cmp --silent "$file" "$TEMP_S3_DIR/$file"; then
            echo "$file is the same in S3, skipping..."
            rm -rf "$file"
        else
            echo "Local $file is different. Uploading to S3..."
            if s3cmd --acl-public put --no-progress "$file" "s3://$BUCKET_NAME/$file"; then
                echo "Uploaded $file to s3://$BUCKET_NAME/$file"
                successful_uploads+=("$file")
            else
                echo "Failed to upload $file."
                failed_uploads+=("$file")
            fi
        fi

        rm -rf "$TEMP_S3_DIR"
    fi
done

# Send summary alert at the end only if there were uploads or failures
if [ ${#successful_uploads[@]} -ne 0 ] || [ ${#failed_uploads[@]} -ne 0 ]; then
    send_slack_alert_with_summary
else
    echo "No new mirroring uploads or failures"
fi
