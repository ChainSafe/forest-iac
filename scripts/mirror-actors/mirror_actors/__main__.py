"""
This script mirrors Filecoin Actor releases from GitHub to an S3 bucket
and sends alerts to a Slack channel in case of failures.
"""

import os
import re
from datetime import datetime
import requests
from dateutil.relativedelta import relativedelta
import boto3
from slack_sdk.web import WebClient
from github import Github

# Define environment variables
SLACK_API_TOKEN = os.environ["SLACK_API_TOKEN"]
SLACK_CHANNEL = os.environ["SLACK_CHANNEL"]
S3_BUCKET = os.environ["S3_BUCKET"]
ENDPOINT_URL = os.environ["ENDPOINT_URL"]
REGION_NAME = os.environ["REGION_NAME"]

GITHUB_REPO = "filecoin-project/builtin-actors"
RELEASE_PATTERN = r'^v\d+\.\d+\.\d+.*$'

# Initialize clients
slack = WebClient(token=SLACK_API_TOKEN)
github = Github()
s3 = boto3.client('s3',
                       region_name=REGION_NAME,
                       endpoint_url=ENDPOINT_URL)

# Calculate the cutoff date (3 years ago from current date)
three_years_ago = datetime.now() - relativedelta(years=3)


def send_slack_alert(message):
    """
    Send an alert message to a predefined Slack channel.

    Args:
        message (str): The message to be sent to Slack.
    """
    slack.chat_postMessage(
        channel=SLACK_CHANNEL,
        text=message
    ).validate()

# Process GitHub releases
try:
    releases = github.get_repo(GITHUB_REPO).get_releases()
    # Fetch already mirrored objects from S3
    s3_response = s3.list_objects(Bucket=S3_BUCKET)
    already_mirrored = set()
    if 'Contents' in s3_response:
        already_mirrored = set(obj["Key"] for obj in s3_response["Contents"])

    for release in releases:
        tag_name = release.tag_name
        # Removing timezone info for comparison
        published_at = release.published_at.replace(tzinfo=None)
        # Skip the release if it's older than 3 years
        if published_at < three_years_ago:
            continue

        if re.match(RELEASE_PATTERN, tag_name):
            for asset in release.get_assets():
                key = f"{tag_name}/{asset.name}"
                if key not in already_mirrored:
                    response = requests.get(asset.browser_download_url, timeout=30)
                    response.raise_for_status()
                    s3.put_object(Bucket=S3_BUCKET, Key=key, Body=response.content)

except Exception as e:
    send_slack_alert(f"⛔ Filecoin Actor mirroring failed: {e}")
    raise
