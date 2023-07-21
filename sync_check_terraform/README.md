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
# New Relic License key, Can be generated here: https://one.eu.newrelic.com/admin-portal/api-keys/home
export TF_VAR_NR_LICENSE_KEY=
```

Forest tokens can be found on 1password.

You also need to register your public key with Digital Ocean. This can be done
here: https://cloud.digitalocean.com/account/security

To prepare terraform for other commands:
```bash
$ terraform init
```

To inspect a new deployment plan (it'll tell you which servers will be removed,
added, etc.):
```bash
$ terraform plan
```

To deploy the service:
```bash
$ terraform apply
```

To shutdown the service:
```bash
$ terraform destroy
```
