import requests
from xml.etree import ElementTree as ET
import re
import os
from datetime import datetime, timezone, timedelta
from slack import WebClient
from slack.errors import SlackApiError
import json

# DigitalOcean Spaces details
region = "fra1"
bucket = "forest-snapshots"
base_url = f"https://{region}.digitaloceanspaces.com/{bucket}"

# Pattern for snapshot file naming
pattern = r'([^_]+?)_snapshot_([^_]+?)_(\d{4}-\d{2}-\d{2})_height_(\d+).car(.zst)?$'

# Specify the folders to check
folders = ["mainnet", "calibnet"]

def slack_alert(message_dict):
    client = WebClient(token=os.environ['SLACK_TOKEN'])
    CHANNEL_ID = 'C05BHMZ7GTT'
    
    # Create formatted message as string resembling JSON
    message = f'```{json.dumps(message_dict, indent=4, ensure_ascii=False)}```'
    
    try:
        response = client.chat_postMessage(channel=CHANNEL_ID, text=message)
        print(f"Message sent. Response: {response['message']}")
    except SlackApiError as e:
        print(f"Slack API error: {e.response['error']}")

def get_snapshots():
    response = requests.get(base_url)
    root = ET.fromstring(response.text)
    snapshots = {}
    for child in root:
        snapshot_dict = {}
        snapshot_name = ''
        # Extracting snapshot details (name, size, and last modified time)
        for snapshot in child:
            if snapshot.tag.endswith('Key'):
                snapshot_name = snapshot.text
            elif snapshot.tag.endswith('Size'):
                snapshot_dict['Size'] = int(snapshot.text)
            elif snapshot.tag.endswith('LastModified'):
                snapshot_dict['LastModified'] = datetime.strptime(snapshot.text, '%Y-%m-%dT%H:%M:%S.%fZ')
        
        # Adding snapshot details to dictionary if file type is valid
        if snapshot_name.endswith(('.car', '.car.zst', '.sha256sum')):
            folder_name = snapshot_name.split('/')[0]
            if folder_name not in snapshots:
                snapshots[folder_name] = {}
            snapshots[folder_name][snapshot_name] = snapshot_dict
    return snapshots

# Main function to perform checks on the snapshots
# For each folder, perform series of checks:
    # - Check if snapshots exist
    # - Verify snapshot age
    # - Confirm snapshot size is > 1GB
    # - Validate snapshot name
    # - Ensure full snapshots have corresponding .sha256sum file
    # - Detect stray .sha256sum files
def main():
    all_snapshots = get_snapshots()
    checks_passed = True

    for folder in folders:  
        snapshots = all_snapshots.get(folder, {}) 

        last_modified_time = None
        latest_snapshot_filename = None
        latest_snapshot_name = None

        for snapshot_name, snapshot in snapshots.items():
            if snapshot_name.endswith(('.car', '.car.zst')) and (last_modified_time is None or snapshot['LastModified'] > last_modified_time):
                last_modified_time = snapshot['LastModified']
                latest_snapshot_filename = snapshot_name
                latest_snapshot_name = snapshot_name.split('/')[-1]  # extract the snapshot name from its full path

        if latest_snapshot_filename is None:
            checks_passed = False
            print(f"No snapshots found in {folder} folder.")
            continue

        # Calculate age of the snapshot in hours
        snapshot_age_hours = (datetime.utcnow() - last_modified_time).total_seconds() / 3600

        if snapshot_age_hours > 30:
            checks_passed = False
            slack_alert(f"⛔ The latest {folder} snapshot: {base_url}/{latest_snapshot_filename} is older than 30 hours (Age: {snapshot_age_hours:.2f} hours). 🔥🌲🔥")
        else:
            slack_alert(f"✅ The latest {folder} snapshot: {base_url}/{latest_snapshot_filename} is not older than 30 hours (Age: {snapshot_age_hours:.2f} hours. 🌲🌳🌲🌳🌲")
            
        for snapshot_name, snapshot in snapshots.items():
            if snapshot['Size'] < 1073741824 and snapshot_name.endswith(('.car', '.car.zst')):  # 1GB in bytes 
                checks_passed = False
                slack_alert(f"🚫 Error! The snapshot {snapshot_name} is less than 1GB. Size anomalies detected. 📉")

            # Check if the snapshot name matches the pattern
            if not re.match(pattern, latest_snapshot_name) and snapshot_name.endswith(('.car', '.car.zst')):
                slack_alert(f"🚫 Error! The snapshot {snapshot_name} does not conform to the standard naming convention. Please check. 📝")

            # Check if full snapshots have a corresponding shasum file
            if snapshot_name.endswith(('.car', '.car.zst')):  # assuming this is a full snapshot
                shasum_file = snapshot_name.rsplit('.', 1)[0] + '.sha256sum'
                if shasum_file not in snapshots:
                    checks_passed = False
                    slack_alert(f"⚠️ Warning! The full snapshot {snapshot_name} is missing its corresponding .sha256sum file. Check required. 🔍")
            elif snapshot_name.endswith('.sha256sum'):  # check for stray shasum files
                snapshot_file = snapshot_name.rsplit('.', 1)[0] + '.car'
                snapshot_file_zst = snapshot_name.rsplit('.', 1)[0] + '.car.zst'
                if snapshot_file not in snapshots and snapshot_file_zst not in snapshots:
                    checks_passed = False
                    print(f"🚨 Error! Stray .sha256sum file {snapshot_name} detected. Please verify. 🕵️")

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
    
