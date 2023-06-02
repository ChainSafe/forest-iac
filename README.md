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

## Forest IAC Architecture

## Overview

This folder contains a Terraform script that provides an executable description of the droplet setup needed for running the Mainnet or Calibnet chains on DigitalOcean. The script automates several steps, including:

- Booting up a New Droplet: It initializes a new droplet with specified parameters such as image, name, region, and size.

- Volume Attachment (optional): The script can optionally attach a storage volume to the droplet if the user specifies so (attach_volume variable set to true). This feature primarily runs for the Mainnet but can also be applied to the Calibnet if set to true. To ensure compliance with device identifier restrictions on DigitalOcean, any "-" characters in the volume name are replaced with "_" by default.

- Running Initialization Script: During the droplet's initialization, the user-data.sh script is executed. This script is templated by the Terraform engine, allowing it to insert variables dynamically as defined in the terraform.tfvars file. The script handles critical tasks such as creating a new user, setting up SSH for the new user, restricting SSH access, and managing Docker-related setups. It's specifically designed to run the Mainnet or Calibnet chain based on the specifications in the Terraform script, and it also initializes Watchtower to keep the Forest images up to date.

## Requirements
The droplet requirements to run Forest Mainnet or Calibnet chain include:
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

- Fill out the `terraform.tfvars` file located in the Terraform Mainnet or Calibnet directory with the values for the following variables:

    - `digitalocean_token`

- Set all necessary environment variables to the terminal permanently by adding them to a shell profile.
    - `export AWS_SECRET_ACCESS_KEY="value"`,
    - `export AWS_ACCESS_KEY_ID="value"`,

Then save the file and restart the terminal for the changes to take effect.

- Navigate to the terraform directory and run `make init_calib` for calibnet or `make init_main` for mainnet to initialize and confirm variables.

- To view all the resources that will be configured, run `make plan_calib` for calibnet or `make plan_main` for mainnet in the terraform directory.

- To create the infrastructure, run `make apply_calib` for calibnet or `make apply_main` for mainnet in the terraform directory.

## Collaborators
Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases, or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to contact the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on interacting with the infrastructure if needed while in deployment.
