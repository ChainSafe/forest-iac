# Overview

This folder contains the necessary configurations and instructions to set up and 
automatically start the Forest Sync-Check service on a DigitalOcean droplet. 
The service will run a sync check on both calibnet and mainnet and 
will also notify the Forest Slack notification channel.

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
# S3 access keys used by terraform, Can be generated here: https://cloud.digitalocean.com/account/api/spaces
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
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
