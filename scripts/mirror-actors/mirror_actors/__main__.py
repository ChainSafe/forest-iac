import os
import re
import requests
from datetime import datetime
from dateutil.relativedelta import relativedelta
import boto3
from slack_sdk.web import WebClient
from github import Github

# Define environment variables
SLACK_API_TOKEN = os.environ["SLACK_API_TOKEN"]
SLACK_CHANNEL = os.environ["SLACK_CHANNEL"]
BUCKET_NAME = os.environ["BUCKET_NAME"]

GITHUB_REPO = "filecoin-project/builtin-actors"
release_pattern = r'^v\d+\.\d+\.\d+.*$'

# Initialize clients
slack = WebClient(token=SLACK_API_TOKEN)
github = Github()
s3 = boto3.client("s3",
                  endpoint_url='https://fra1.digitaloceanspaces.com')

# Calculate the cutoff date (3 years ago from current date)
three_years_ago = datetime.now() - relativedelta(years=3)


def send_slack_alert(message):
    slack.chat_postMessage(
        channel=SLACK_CHANNEL,
        text=message
    ).validate()

# Process GitHub releases
try:
    releases = github.get_repo(GITHUB_REPO).get_releases()
    # Fetch already mirrored objects from S3
    s3_response = s3.list_objects(Bucket=BUCKET_NAME)
    already_mirrored = set()
    if 'Contents' in s3_response:
        already_mirrored = set(obj["Key"] for obj in s3_response["Contents"])

    for release in releases:
        tag_name = release.tag_name
        published_at = release.published_at.replace(tzinfo=None)  # Removing timezone info for comparison

        # Skip the release if it's older than 3 years
        if published_at < three_years_ago:
            continue

        if re.match(release_pattern, tag_name):
            for asset in release.get_assets():
                key = f"{tag_name}/{asset.name}"
                if key not in already_mirrored:
                    response = requests.get(asset.browser_download_url)
                    response.raise_for_status()
                    s3.put_object(Bucket=BUCKET_NAME, Key=key, Body=response.content)

except Exception as e:
    send_slack_alert(f"⛔ Filecoin Actor mirroring failed: {e}")
    raise
