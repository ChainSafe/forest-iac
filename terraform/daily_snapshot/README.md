# Overview

This directory contains an infrastructure configuration for the Forest service,
which generates the latest snapshots available at this endpoint:
https://forest-archive.chainsafe.dev/latest/mainnet/ and
https://forest-archive.chainsafe.dev/latest/calibnet/

# Workflow

Changing any of the settings (such as the size of the droplet or the operating
system) will automatically re-deploy the service. The same is true for changing
any of the scripts.

To propose new changes, start by opening a PR. This will trigger a new
deployment plan to be pasted in the PR comments. Once the PR is merged, the
deployment plan is executed.

The workflow has access to all the required secrets (DO token, slack token, S3
credentials, etc) and none of them have to be provided when creating a new PR.
However, the deployment workflow is not triggered automatically if you change
the secrets. In this case, you have to trigger the workflow manually.

# Manual deployments

To manually deploy the service (useful for testing and debugging), you first
need to set the following environment variables (you will be prompted later if
you don't set these variables):

## Required environment variables

```bash
# DigitalOcean personal access token: https://cloud.digitalocean.com/account/api/tokens
export TF_VAR_do_token=
# Slack access token: https://api.slack.com/apps
export TF_VAR_slack_token=
# S3 access keys used by terraform. Can be generated here: https://cloud.digitalocean.com/account/api/spaces
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

# Cloudflare R2 secret access keys used by the snapshot service.
export TF_VAR_R2_ACCESS_KEY=
export TF_VAR_R2_SECRET_KEY=
```

Forest tokens can be found on 1password.

Playbook:

```bash
$ terraform init      # Initialize terraform state
$ terraform plan      # Show deployment plan (optional)
$ terraform apply     # Apply deployment plan
$ terraform destroy   # Destroy deployment
```

For Mac users, if you encounter the `Error: External Program Execution Failed`, you'll need to adjust the `prep_sources.sh` file located in the `../modules/daily_snapshot` directory. Make the following changes:

- Replace `--archive` with `-Rp`.
- Install `gnu-tar` using the command `brew install gnu-tar`. Afterward, switch `tar cf ../sources.tar` to `gtar cf ../sources.tar`
