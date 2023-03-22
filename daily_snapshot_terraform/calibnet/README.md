# Overview

This folder contains an executable description of the Forest service for
generating daily snapshots. The service will continuously verify that Forest can
export snapshots. Once per day, this service will sync to calibnet and export a
new snapshot. If the previous snapshot is more than a day old, the new snapshot
is uploaded to Digital Ocean Spaces.


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
# Fingerprint of SSH key registered with DigitalOcean: https://cloud.digitalocean.com/account/security
export TF_VAR_ssh_fingerprint=
# S3 access keys used by the snapshot service. Can be generated here: https://cloud.digitalocean.com/account/api/spaces
export TF_VAR_AWS_ACCESS_KEY_ID=
export TF_VAR_AWS_SECRET_ACCESS_KEY=
# S3 access keys used by terraform, use the same values as above
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

Forest tokens can be found on 1password. The SSH fingerprint needs to be
registered with Digital Ocean.

To inspect a new deployment plan (it'll tell you which servers will be removed,
added, etc):
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
