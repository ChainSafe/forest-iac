# Overview

This folder contains an infrastructure configuration that simplifies the setup and automatic initiation of the Forest Sync-Check service on a DigitalOcean droplet. The configuration is specifically designed to perform sync checks on both the Calibnet and Mainnet networks. It also sends notifications to the Forest Slack notification channel. Moreover, the sync check service is configured to automatically restart upon droplet reboot, and the New Relic Infrastructure agent is installed for monitoring purposes

# Workflow

Changing any of the settings (such as the size of the droplet or the operating
system) will automatically re-deploy the service. The same is true for changing
any of the scripts.

The sync check is configured using `restart unless-stopped` docker flag, 
which restart automatically upon droplet reboot.

The workflow has access to all the required secrets (DO token, slack token, S3
credentials) and none of them have to be provided when creating a new PR.
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
# S3 access keys used by the snapshot service. Can be generated here: https://cloud.digitalocean.com/account/api/spaces
export TF_VAR_AWS_ACCESS_KEY_ID=
export TF_VAR_AWS_SECRET_ACCESS_KEY=
# S3 access keys used by terraform, use the same values as above
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

# Optional, only if you want install new relic agent
# New Relic License key, Can be generated here: https://one.eu.newrelic.com/admin-portal/api-keys/home
export TF_VAR_NEW_RELIC_API_KEY=
export TF_VAR_NEW_RELIC_ACCOUNT_ID=
```

Forest tokens can be found on 1password.

you'll also need to link your public key with Digital Ocean. To do this, visit https://cloud.digitalocean.com/account/security. Additionally, set up your SSH key by following the commands provided below:

```bash
eval $(ssh-agent)

ssh-add <path_to_your_ssh_key>
```

To ensure the production Snapshot service remains intact, modify certain variables in the `Main.tf` file:

- Change `key = "sync_check.tfstate"` to `key = "<your_custom_name>.tfstate"`.
- Replace `name = "forest-sync-check"` with `name = "<your_desired_name>"`.
- Replace ` slack_channel = "#forest-notifications"` with  `slack_channel = "#forest-dump"`

Remember to replace `<path_to_your_ssh_key>`, `<your_custom_name>`, and `<your_desired_name>` with appropriate values.

To prepare terraform for other commands:
```bash
$ terraform init
```

To inspect a new deployment plan (it'll tell you which servers will be removed,
added, etc.):
```bash
$ terraform plan
```
For Mac users, if you encounter the `Error: External Program Execution Failed`, you'll need to adjust the `prep_sources.sh` file located in the `../modules/sync_check` directory. Make the following changes:

- Replace `--archive` with `-Rp`.
- Install `gnu-tar` using the command `brew install gnu-tar`. Afterward, switch `tar cf ../sources.tar` to `gtar cf ../sources.tar`

To deploy the service:
```bash
$ terraform apply
```

To shutdown the service:
```bash
$ terraform destroy
```
