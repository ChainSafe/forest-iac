# Overview
This project automates the process of mirroring Filecoin's built-in actors' releases from GitHub to cloud storage services (DigitalOcean Spaces and CloudFlare R2). The script checks for new releases on GitHub, downloads them, and uploads them to the specified cloud storage. It's designed to run periodically and ensures that the latest releases are always available in the cloud storage.


# Workflow

The project uses GitHub Actions for automated deployment:

- **Frequency**: The script runs every hour (0 * * * *).
- **Triggered By**: Changes in the scripts/mirror-actors/** path in the repository. This includes both pull requests and push events.
- **Manual Trigger**: The workflow can also be triggered manually via the GitHub UI (workflow_dispatch event).

# Manual deployments

For manual deployments, particularly useful for testing and debugging, set the following environment variables:

## Required environment variables

```bash
# DigitalOcean or CloudFlare Access Tokens depending which cloud you want to mirror to
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

# Slack Access Token and channel
export SLACK_API_TOKEN=
export SLACK_CHANNEL=

# s3 Boto client Configurations
export BUCKET_NAME=
export REGION_NAME=
export ENDPOINT_URL=
```

Playbook:

```bash
$ poetry install --no-interaction --no-root         # Install dependencies
$ poetry run python3 mirror_actors/                 # Run the mirroring script
```
