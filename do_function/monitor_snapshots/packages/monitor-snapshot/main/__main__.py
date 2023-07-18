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
def slack_alert(message, thread_ts=None):
    # Instantiate a Slack client with token from environment variables.
    client = WebClient(token=os.environ['SLACK_TOKEN'])
    CHANNEL_NAME = '#forest-notifications'

    # Format message as a JSON-like string for better readability.
    message = f'```{json.dumps(message, indent=4, ensure_ascii=False)}```'

    # Try sending message, catch and print any errors.
    try:
        response = client.chat_postMessage(channel=CHANNEL_NAME, text=message, thread_ts=thread_ts)
        print(f"Message sent. Response: {response['message']}")
        return response['ts']
    except SlackApiError as e:
        print(f"Slack API error: {e.response['error']}")
        return None

# Function to get and return details of all snapshots
def get_snapshots():
    # Make a request to the base_url to retrieve snapshots
    response = requests.get(base_url)

    # Parse the XML response to a tree structure for processing
    root = ET.fromstring(response.text)
    snapshots = {}

    # Iterate through the XML tree structure
    for child in root:
        snapshot_dict = {}
        snapshot_name = ''

        # Capture the necessary snapshot details
        for snapshot in child:
            if snapshot.tag.endswith('Key'):
                snapshot_name = snapshot.text
            elif snapshot.tag.endswith('Size'):
                snapshot_dict['Size'] = int(snapshot.text)

        # Filter only snapshots ending with the specified extensions
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
    # Retrieve all snapshots and details
    all_snapshots = get_snapshots()
    checks_passed = True

    # Iterate over each folder and check the snapshots within.
    for folder in folders:  
        # Get the snapshots in the current folder
        snapshots = all_snapshots.get(folder, {}) 

        latest_snapshot_by_date = None
        latest_snapshot_filename = None
        latest_snapshot_name = None
        error_messages = []  # List to store error messages

        # Find the most recent snapshot in the current folder by snapshot date.
        for snapshot_name, snapshot in snapshots.items():
            if snapshot_name.endswith(('.car', '.car.zst')) and (latest_snapshot_by_date is None or snapshot['Date'] > latest_snapshot_by_date):
                latest_snapshot_by_date = snapshot['Date']
                latest_snapshot_filename = snapshot_name
                latest_snapshot_name = snapshot_name.split('/')[-1]  # Extract snapshot name from full path.

        # If there are no snapshots in the folder, notify and skip to next folder.
        if latest_snapshot_filename is None:
            checks_passed = False
            error_messages.append(f"No snapshots found in {folder} folder.")
            continue       

        # Check if the most recent snapshot is older than one day.
        current_date_utc = datetime.now(timezone.utc).date()
        yesterday_date_utc = current_date_utc - timedelta(days=1)

        if latest_snapshot_by_date.date() < yesterday_date_utc:
            checks_passed = False
            error_messages.append(f"⛔ The latest {folder} snapshot: {base_url}/{latest_snapshot_filename} is older than one day. Snapshot Date: {latest_snapshot_by_date}, Current Date: {current_date_utc}. 🔥🌲🔥")
        
        # Checks for validity and integrity of each snapshot in the current folder.
        for snapshot_name, snapshot in snapshots.items():
            # Check if the snapshot size is less than 1GB.
            if snapshot['Size'] < 1073741824 and snapshot_name.endswith(('.car', '.car.zst')):  # 1GB in bytes 
                checks_passed = False
                error_messages.append(f"🚫 Error! The snapshot {snapshot_name} is less than 1GB. Size anomalies detected. 📉")

            # Check if the snapshot name matches the naming pattern.
            if not re.match(pattern, latest_snapshot_name) and snapshot_name.endswith(('.car', '.car.zst')):
                error_messages.append(f"🚫 Error! The snapshot {snapshot_name} does not conform to the standard naming convention. Please check. 📝")

            # Check if full snapshots have a corresponding sha256 checksum file.
            if snapshot_name.endswith(('.car', '.car.zst')):  # assuming this is a full snapshot
                base_snapshot_name = snapshot_name.rsplit('.', 1)[0] # Remove the last extension
                shasum_file = base_snapshot_name + '.sha256sum'
                shasum_file_no_ext = base_snapshot_name.rsplit('.', 1)[0] + '.sha256sum'  # For case without the '.car' in sha256sum filename.
                if shasum_file not in snapshots and shasum_file_no_ext not in snapshots:  # Check for both
                    checks_passed = False
                    error_messages.append(f"⚠️ Warning! The full snapshot {snapshot_name} is missing its corresponding .sha256sum file. Check required. 🔍")

            # Check if there are any sha256 checksum files without a corresponding snapshot file.
            elif snapshot_name.endswith('.sha256sum'):  # Check for stray shasum files
                base_snapshot_file = snapshot_name.rsplit('.', 2)[0] 
                snapshot_file = base_snapshot_file + '.car'
                snapshot_file_zst = base_snapshot_file + '.car.zst'
                if snapshot_file not in snapshots and snapshot_file_zst not in snapshots:
                    checks_passed = False
                    error_messages.append(f"🚨 Error! Stray .sha256sum file {snapshot_name} detected. Please verify. 🕵️")

    # If checks fail, send a general failure message to Slack.
    if not checks_passed:
        thread = slack_alert("⛔ Snapshot check failed. 🔥🌲🔥")
        for error_message in error_messages:
            slack_alert({"error": error_message}, thread_ts=thread)
        return {
            "result": "⛔ failure",
            "message": "Some checks did not pass. Please review the issues reported. Let's fix them and keep the forest green!. 🔥🌲🔥"
        }
    else:
        return {
            "result": "✅ success",
            "message": "All checks passed successfully. All snapshots are valid and up-to-date. Lets keep up the good work!. 🌲🌳🌲🌳🌲"
        }

