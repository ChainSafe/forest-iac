"""
This script mirrors Filecoin Actor releases from GitHub to a specified storage sink.
It supports uploading to an S3 bucket or saving locally, based on configuration.
Alerts are sent to a Slack channel in case of failures.
"""

import os
import re
import abc
from datetime import datetime
import requests
from dateutil.relativedelta import relativedelta
import boto3
from slack_sdk.web import WebClient
from github import Github

# Define environment variables
SLACK_API_TOKEN = os.environ["SLACK_API_TOKEN"]
SLACK_CHANNEL = os.environ["SLACK_CHANNEL"]
BUCKET_NAME = os.environ["BUCKET_NAME"]
ENDPOINT_URL = os.environ["ENDPOINT_URL"]
REGION_NAME = os.environ["REGION_NAME"]

GITHUB_REPO = "filecoin-project/builtin-actors"
RELEASE_PATTERN = r'^v\d+\.\d+\.\d+.*$'

# Initialize clients
slack = WebClient(token=SLACK_API_TOKEN)
github = Github()
s3 = boto3.client('s3', region_name=REGION_NAME, endpoint_url=ENDPOINT_URL)

# Calculate the cutoff date (3 years ago from the current date)
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

# Abstract class for a data sink
class AbstractSink(abc.ABC):
    """
    Abstract class for defining a data sink.
    """
    @abc.abstractmethod
    def save(self, data_key, content):
        """
        Save content to the specified key.

        Args:
            data_key (str): The key where the content will be saved.
            content: The content to be saved.
        """

    @abc.abstractmethod
    def exists(self, data_key):
        """
        Check if a file exists in the sink.

        Args:
            data_key (str): The key or path to check.

        Returns:
            bool: True if the file exists, False otherwise.
        """

# S3 data sink
class S3Sink(AbstractSink):
    """
    S3 data sink for saving content to an S3 bucket.
    """
    def __init__(self, bucket):
        """
        Initialize the S3 client.

        Args:
            bucket (str): The S3 bucket name.
        """
        self.s3 = s3
        self.bucket = bucket

    def save(self, data_key, content):
        """
        Save content to the specified key in the S3 bucket.

        Args:
            sink_key (str): The key where the content will be saved.
            content (bytes): The content to be saved.
        """
        self.s3.put_object(Bucket=self.bucket, Key=data_key, Body=content)

    def exists(self, data_key):
        """
        Check if a file exists in the S3 bucket.

        Args:
            data_key (str): The key of the file to check.

        Returns:
            bool: True if the file exists, False otherwise.
        """
        try:
            self.s3.head_object(Bucket=self.bucket, Key=data_key)
            return True
        except self.s3.exceptions.NoSuchKey:
            return False

# Local data sink
class LocalSink(AbstractSink):
    """
    Local data sink for saving files to the local file system.

    Attributes:
        base_dir (str): Base directory where files will be mirrored.
    """
    def __init__(self, base_dir):
        self.base_dir = base_dir

    def save(self, data_key, content):
        full_path = os.path.join(self.base_dir, data_key)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)

        with open(full_path, 'wb') as file:
            file.write(content)

    def exists(self, data_key):
        full_path = os.path.join(self.base_dir, data_key)
        return os.path.exists(full_path)

# Factory method to create the appropriate sink
def create_sink(sink_type, base_dir=None, **kwargs):
    """
    Create and return the appropriate sink based on the specified type.

    Args:
        sink_type (str): The type of sink to create ("S3" or "Local").
        base_dir (str, optional): Base directory for LocalSink, ignored for S3Sink.
        **kwargs: Additional keyword arguments specific to the sink type.

    Returns:
        AbstractSink: An instance of either S3Sink or LocalSink.

    Raises:
        ValueError: If an invalid sink type is provided.
    """
    if sink_type == "S3":
        return S3Sink(**kwargs)
    if sink_type == "Local":
        return LocalSink(base_dir or "")
    raise ValueError("Invalid sink type. Please Provide valid sink type, e.g S3 or Local")


SINK_TYPE = os.environ.get("SINK_TYPE", "Local")
LOCAL_SAVE_PATH = os.environ.get("LOCAL_SAVE_PATH", ".")
sink = create_sink(SINK_TYPE, bucket=BUCKET_NAME)

# Process GitHub releases
try:
    releases = github.get_repo(GITHUB_REPO).get_releases()
    s3_response = s3.list_objects(Bucket=BUCKET_NAME)
    already_mirrored = set()
    if 'Contents' in s3_response:
        already_mirrored = {obj["Key"] for obj in s3_response["Contents"]}

    for release in releases:
        tag_name = release.tag_name
        published_at = release.published_at.replace(tzinfo=None)
        if published_at < three_years_ago:
            continue

        if re.match(RELEASE_PATTERN, tag_name):
            for asset in release.get_assets():
                release_key = f"{tag_name}/{asset.name}"
                if release_key not in already_mirrored:
                    response = requests.get(asset.browser_download_url, timeout=30)
                    response.raise_for_status()
                    sink.save(release_key, response.content)

except Exception as e:
    send_slack_alert(f"⛔ Filecoin Actor mirroring failed: {e}")
    raise
