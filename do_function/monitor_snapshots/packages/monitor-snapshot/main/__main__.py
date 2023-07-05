import requests
from xml.etree import ElementTree as ET
import re
import os
from datetime import datetime, timezone, timedelta
from slack import WebClient
from slack.errors import SlackApiError
import json

# Define the DigitalOcean Spaces region and bucket.
region = "fra1"
bucket = "forest-snapshots"
base_url = f"https://{region}.digitaloceanspaces.com/{bucket}"

# Define the pattern for valid snapshot file names.
pattern = r'([^_]+?)_snapshot_([^_]+?)_(\d{4}-\d{2}-\d{2})_height_(\d+).car(.zst)?$'

# Define the folders that the script should scan for snapshots.
folders = ["mainnet", "calibnet"]

# Function to send alert messages to a Slack channel.
def slack_alert(message_dict):
    # Instantiate a Slack client with token from environment variables.
    client = WebClient(token=os.environ['SLACK_TOKEN'])
    CHANNEL_NAME = '#forest-dump'
    
    # Format message as a JSON-like string for better readability.
    message = f'```{json.dumps(message_dict, indent=4, ensure_ascii=False)}```'
    
    # Try sending message, catch and print any errors.
    try:
        response = client.chat_postMessage(channel=CHANNEL_NAME, text=message)
        print(f"Message sent. Response: {response['message']}")
    except SlackApiError as e:
        print(f"Slack API error: {e.response['error']}")

# Function to send alert messages to a Slack channel.
def get_snapshots():
    response = requests.get(base_url)
    root = ET.fromstring(response.text)
    snapshots = {}
    for child in root:
        snapshot_dict = {}
        snapshot_name = ''
        for snapshot in child:
            if snapshot.tag.endswith('Key'):
                snapshot_name = snapshot.text
            elif snapshot.tag.endswith('Size'):
                snapshot_dict['Size'] = int(snapshot.text)

        if snapshot_name.endswith(('.car', '.car.zst', '.sha256sum')):
            folder_name = snapshot_name.split('/')[0]
            if folder_name not in snapshots:
                snapshots[folder_name] = {}

            match = re.match(pattern, snapshot_name)
            if match:
                snapshot_date_str = match.group(3)
                snapshot_dict['Date'] = datetime.strptime(snapshot_date_str, '%Y-%m-%d')
            snapshots[folder_name][snapshot_name] = snapshot_dict
    return snapshots

# The main function checks the validity and integrity of the snapshots.
def main():
    all_snapshots = get_snapshots()
    checks_passed = True

    # Iterate over each folder and check the snapshots within.
    for folder in folders:  
        snapshots = all_snapshots.get(folder, {}) 

        latest_snapshot_by_date = None
        latest_snapshot_filename = None
        latest_snapshot_name = None

        # Find the most recent snapshot in the current folder by snapshot date.
        for snapshot_name, snapshot in snapshots.items():
            if snapshot_name.endswith(('.car', '.car.zst')) and (latest_snapshot_by_date is None or snapshot['Date'] > latest_snapshot_by_date):
                latest_snapshot_by_date = snapshot['Date']
                latest_snapshot_filename = snapshot_name
                latest_snapshot_name = snapshot_name.split('/')[-1]  # Extract snapshot name from full path.

        # If there are no snapshots in the folder, notify and skip to next folder.
        if latest_snapshot_filename is None:
            checks_passed = False
            print(f"No snapshots found in {folder} folder.")
            continue       

        # Check if the most recent snapshot is older than one day.
        current_date_utc = datetime.now(timezone.utc).date()
        yesterday_date_utc = current_date_utc - timedelta(days=1)

        if latest_snapshot_by_date.date() < yesterday_date_utc:
            checks_passed = False
            slack_alert(f"⛔ The latest {folder} snapshot: {base_url}/{latest_snapshot_filename} is older than one day. Snapshot Date: {latest_snapshot_by_date}, Current Date: {current_date_utc}. 🔥🌲🔥")
        else:
            slack_alert(f"✅ The latest {folder} snapshot: {base_url}/{latest_snapshot_filename} is from today or yesterday. Snapshot Date: {latest_snapshot_by_date}, Current Date: {current_date_utc}. 🌲🌳🌲🌳🌲")
        
        # Checks for validity and integrity of each snapshot in the current folder.
        
        for snapshot_name, snapshot in snapshots.items():
            # Check if the snapshot size is less than 1GB.
            if snapshot['Size'] < 1073741824 and snapshot_name.endswith(('.car', '.car.zst')):  # 1GB in bytes 
                checks_passed = False
                slack_alert(f"🚫 Error! The snapshot {snapshot_name} is less than 1GB. Size anomalies detected. 📉")

            # Check if the snapshot name matches the naming pattern.
            if not re.match(pattern, latest_snapshot_name) and snapshot_name.endswith(('.car', '.car.zst')):
                slack_alert(f"🚫 Error! The snapshot {snapshot_name} does not conform to the standard naming convention. Please check. 📝")

            # Check if full snapshots have a corresponding sha256 checksum file.
            if snapshot_name.endswith(('.car', '.car.zst')):  # assuming this is a full snapshot
                shasum_file = snapshot_name.rsplit('.', 1)[0] + '.sha256sum'
                if shasum_file not in snapshots:
                    checks_passed = False
                    slack_alert(f"⚠️ Warning! The full snapshot {snapshot_name} is missing its corresponding .sha256sum file. Check required. 🔍")

            # Check for any stray sha256 checksum files.
            elif snapshot_name.endswith('.sha256sum'):  # Check for stray shasum files
                snapshot_file = snapshot_name.rsplit('.', 1)[0] + '.car'
                snapshot_file_zst = snapshot_name.rsplit('.', 1)[0] + '.car.zst'
                if snapshot_file not in snapshots and snapshot_file_zst not in snapshots:
                    checks_passed = False
                    slack(f"🚨 Error! Stray .sha256sum file {snapshot_name} detected. Please verify. 🕵️")

    # If all checks have passed, send success message. Otherwise, send failure message.
    if checks_passed:
        message = {"result": "✅ success", 
                   "message": "All checks passed successfully. All snapshots are valid and up-to-date. Lets keep up the good work! 🌲🌳🌲🌳🌲"}
        slack_alert(message)
        return message
    else:
        message = {"result": "⛔ failure", 
                   "message": "Some checks did not pass. Please review the issues reported above. Let's fix them and keep the forest green! 🔥🌲🔥"}
        slack_alert(message)
        return message
