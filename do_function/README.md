This folder contains the DigitalOcean Function responsible for redirecting to the Forest snapshot with the highest epoch. Additionally, it includes a function that monitors the forest snapshot bucket.

Changes made to the scripts will be automatically deployed using the CI script.

Manual deployments can be done using `doctl`:

## Requirements
- [Doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/) 
- VCPU: 1
- Disk Size: >100 GB
- Install `make`

Before deploying, make sure to install the necessary dependencies by running:

```bash
# DigitalOcean personal access token: https://cloud.digitalocean.com/account/api/tokens
export TF_VAR_do_token=

# # Slack access token: https://api.slack.com/apps
export SLACK_TOKEN=

make install
```

To deploy the redirecting function, execute the following commands:

```
make con_link

make deploy_link
```

To deploy the Monitoring spaces function, run the following commands:

```
make con_spaces

make deploy_snap
```