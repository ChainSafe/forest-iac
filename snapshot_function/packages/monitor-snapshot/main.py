import requests
from xml.etree import ElementTree as ET
from datetime import datetime, timezone
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
import re

# Configuration constants
region = "fra1"
bucket = "forest-snapshots"
base_url = f"https://{region}.digitaloceanspaces.com/{bucket}"

SLACK_TOKEN = 'your_slack_bot_token'
CHANNEL_ID = 'your_slack_channel_id'

SNAPSHOT_PATTERN = r'([^_]+?)_snapshot_([^_]+?)_(\d{4}-\d{2}-\d{2})_height_(\d+).car(.zst)?$'
FULL_SNAPSHOT_EXTENSION = '.tar.gz'
SHASUM_EXTENSION = '.shasum'

GB_IN_BYTES = 1073741824
HOURS_THRESHOLD = 30

class AlertSender:
    def __init__(self):
        self.client = WebClient(token=SLACK_TOKEN)

    def send(self, message):
        try:
            response = self.client.chat_postMessage(channel=CHANNEL_ID, text=message)
            assert response["message"]["text"] == message
        except SlackApiError as e:
            print(f"Got an error: {e.response['error']}")

class FileChecker:
    def __init__(self, alert_sender):
        self.alert_sender = alert_sender

    def check(self, file):
        pass

class SizeChecker(FileChecker):
    def check(self, file):
        if file['Size'] < GB_IN_BYTES:
            self.alert_sender.send(f"File {file['Name']} is smaller than 1GB")

class PatternChecker(FileChecker):
    def check(self, file):
        if not re.match(SNAPSHOT_PATTERN, file['Name']):
            self.alert_sender.send(f"File {file['Name']} does not match the name pattern")

class ShasumChecker(FileChecker):
    def check(self, file, files):
        if file['Name'].endswith(FULL_SNAPSHOT_EXTENSION) and f"{file['Name']}{SHASUM_EXTENSION}" not in files:
            self.alert_sender.send(f"Full snapshot {file['Name']} does not have a corresponding shasum file")
        elif file['Name'].endswith(SHASUM_EXTENSION) and file['Name'].rsplit('.', 1)[0] not in files:
            self.alert_sender.send(f"Stray shasum file {file['Name']} found")

def get_files():
    response = requests.get(BASE_URL)
    root = ET.fromstring(response.content)

    files = {}
    for child in root:
        file = {}
        for detail in child:
            if detail.tag.endswith('Key'):
                file['Name'] = detail.text
            elif detail.tag.endswith('Size'):
                file['Size'] = int(detail.text)
            elif detail.tag.endswith('LastModified'):
                file['LastModified'] = datetime.strptime(detail.text, '%Y-%m-%dT%H:%M:%S.%fZ')
        files[file['Name']] = file
    return files

def main():
    files = get_files()
    alert_sender = AlertSender()
    checkers = [SizeChecker(alert_sender), PatternChecker(alert_sender), ShasumChecker(alert_sender)]

    last_modified = max(file['LastModified'] for file in files.values())
    if (datetime.now(timezone.utc) - last_modified).total_seconds() > HOURS_THRESHOLD * 3600:
        alert_sender.send("Last snapshot is older than 30 hours")

    for file in files.values():
        for checker in checkers:
            checker.check(file, files)

if __name__ == "__main__":
    main()
