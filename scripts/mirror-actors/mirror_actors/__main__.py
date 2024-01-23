"""
This script mirrors Filecoin Actor releases from GitHub to a specified storage sink.
It supports uploading to an S3 bucket or saving locally, based on configuration.
Alerts are sent to a Slack channel in case of failures.
"""

import os
import re
from datetime import datetime
import requests
from dateutil.relativedelta import relativedelta
import boto3
from slack_sdk.web import WebClient
from github import Github

GITHUB_REPO = "filecoin-project/builtin-actors"
RELEASE_PATTERN = r'^v\d+\.\d+\.\d+.*$'

# Initialize GitHub client
github = Github()

# Calculate the cutoff date (3 years ago from the current date)
three_years_ago = datetime.now() - relativedelta(years=3)

def send_slack_alert(message):
    """
    Send an alert message to a predefined Slack channel.
    """
    slack_api_token = os.environ["SLACK_API_TOKEN"]
    slack_channel = os.environ["SLACK_CHANNEL"]
    slack = WebClient(token=slack_api_token)
    slack.chat_postMessage(channel=slack_channel, text=message).validate()

def save_to_s3(key, content):
    """
    Save content to S3 bucket.
    """
    # Retrieve S3 configuration from environment variables
    bucket_name = os.environ.get("BUCKET_NAME")
    endpoint_url = os.environ.get("ENDPOINT_URL")
    region_name = os.environ.get("REGION_NAME")

    # Initialize and use S3 client
    s3 = boto3.client('s3', endpoint_url=endpoint_url, region_name=region_name)
    s3.put_object(Bucket=bucket_name, Key=key, Body=content)


def save_to_local(base_dir, key, content):
    """
    Mirror Actors to local filesystem.
    """
    full_path = os.path.join(base_dir, key)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'wb') as file:
        file.write(content)

# Configuration
USE_LOCAL = os.environ.get("USE_LOCAL", "False") == "True"
LOCAL_SAVE_PATH = os.environ.get("LOCAL_SAVE_PATH", ".")

# Process GitHub releases
try:
    releases = github.get_repo(GITHUB_REPO).get_releases()

    for release in releases:
        tag_name = release.tag_name
        published_at = release.published_at.replace(tzinfo=None)
        if published_at < three_years_ago:
            continue

        if re.match(RELEASE_PATTERN, tag_name):
            for asset in release.get_assets():
                release = f"{tag_name}/{asset.name}"
                response = requests.get(asset.browser_download_url, timeout=30)
                response.raise_for_status()

                # Save using the appropriate sink
                if USE_LOCAL:
                    save_to_local(LOCAL_SAVE_PATH, release, response.content)
                else:
                    save_to_s3(release, response.content)

except Exception as e:
    error_message = f"⛔ Filecoin Actor mirroring failed: {e}"
    send_slack_alert(error_message)
    raise
