# 🌲 Forest IaC

This repository contains machine-readable specifications for the auxillilary services that [Forest](https://github.com/ChainSafe/forest) project running smoothly. The services include daily uploads of network snapshots, and automated testing of Forest's capabilities.

# 🔧 Desired properties

 - Require minimal setup. Ideally any server with [docker](https://www.docker.com/) installed should be sufficient.
 - Automatic and error-proof re-deployment when new infrastructure code is available.
 - Runs without human intervention. The services should stay running unless explicitly stopped.
 - Fault tolerant.
 - Use a consistent strategy for uploading/storing logs and reporting errors.
 - Is idempotent. Multiple instances can run without adverse effect.
 - Is sanity checked. Shell scripts with `shellcheck`, Ruby scripts with `RuboCop`, Rust with `clippy`.

# ⚡ Services

- [x] Daily calibnet snapshots.
- [x] Sync testing for Forest docker image.
- [ ] Exhaustive RPC testing for Forest docker image.
- [ ] Sync testing for PRs.
- [ ] Export testing for PRs.

# 🛠️ Forest Cloud Infrastructure In DigitalOcean

## Overview

The Terraform folder contains terraform scripts to automate the setup of droplets on DigitalOcean. These scripts enable the configuration of essential infrastructure required for running Forest Mainnet, Calibnet, or Lotus Mainnet nodes. The script automates several steps, including:

- Booting up a New Droplet: It initializes a new droplet with specified parameters such as image, name, region, and size.

- Volume Attachment (optional): The script can optionally attach a storage volume to the droplet if the user specifies so (attach_volume variable set to true). This feature primarily runs on the Mainnet but can also be applied to the Calibnet if set to true. To ensure compliance with device identifier restrictions on DigitalOcean, any "-" characters in the volume name are automatically replaced with "_" when mounting the volume on the droplet.

- Running Initialization Script: The `user-data.sh` or `lotus.sh` script is executed during the droplet's initialization. This script is powered by the Terraform engine and allows dynamic insertion of variables from the `terraform.tfvars` file. It handles crucial tasks such as creating a new user, configuring SSH settings, restricting SSH access, and managing Docker-related setups. Its purpose is to specifically run the Mainnet or Calibnet chain based on the specifications provided in the Terraform script. Additionally, it initializes Watchtower to ensure the Forest images are up to date and configures the New Relic infrastructure agent and Openmetrics New Relic container exclusively on the forest nodes.

## Requirements
The droplet requirements to run Forest Mainnet, Calibnet or lotus mainnet nodes include:
- RAM: 8GB
- VCPU: 1
- Disk Size: >100 GB

The user's local machine requirements include the following:
- Install [Terraform](https://developer.hashicorp.com/terraform/downloads)
- Install `make`
- Basic DigitalOcean knowledge

To implement the infrastructure, run the following:
- Create an `ssh-key` to be added to the DigitalOcean list and store the fingerprint for use in the next few steps; you can check more details [here](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/to-team/)

- Create a space on DigitalOcean with any preferred unique name, then add the bucket name and endpoint to the `backend.tf` file located in the terraform Mainnet or Calibnet directory, depending on which one you plan to run.

- Generate `digitalocean_api_token` from DigitalOcean console; you can check [here](https://docs.digitalocean.com/reference/api/create-personal-access-token/) for more details.

If you need to run this locally, you first need to set the following environment variables (you will be prompted later if you don't put these variables):

```bash
# DigitalOcean personal access token
export TF_VAR_do_token=<digitalocean_api_token>
# S3 access keys used by terraform. Can be generated here: https://cloud.digitalocean.com/account/api/spaces
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

# Optional, only if you want install new relic agent
# New Relic details used, Can be gotten here: https://one.eu.newrelic.com/admin-portal/api-keys/home
export TF_VAR_NEW_RELIC_API_KEY=
export TF_VAR_NEW_RELIC_ACCOUNT_ID=
export TF_VAR_NR_LICENSE_KEY=
```
Then save the file and restart the terminal for the changes to take effect.

- Navigate to the terraform directory and run `make init_calib` for calibnet, `make init_main` for mainnet, or `make init_lt_main` for lotus mainnet to initialize and verify variables.

- Run `make plan_calib` for calibnet, `make plan_main` for mainnet, or `make plan_lt_main` for lotus mainnet in the terraform directory to view all the configured resources.

- To create the infrastructure, run `make apply_calib` for calibnet, `make apply_main` for mainnet, or `make apply_lt_main` for lotus mainnet in the terraform directory.

## Collaborators
Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases, or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to contact the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on interacting with the infrastructure if the need arises during deployment.
