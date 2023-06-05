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

![Forest Diagram With Monitoring](https://user-images.githubusercontent.com/47984109/226943527-c7c0a053-8ba6-4d9f-9392-8d68cfbfca3e.png)

### Requirements
The droplet requirements to run forest include:
- RAM: 8GB
- VCPU: 1
- Disk Size: >100 GB (for mainnet, it should be >500GB)

The user's local machine requirements include:
- Install [Terraform](https://developer.hashicorp.com/terraform/downloads) and [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).
- Install `make`
- Basic DigitalOcean knowledge

To implement the infrastructure, run the following:
- Create an `ssh-key` to be added to the DigitalOcean list and store the fingerprint for use in the next few steps; you can check more details [here](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/to-team/)
- Create a space on DigitalOcean with any preferred unique name then add the bucket name and endpoint in the `backend.tf` file.
- Generate `digitalocean_api_token` from DigitalOcean console; you can check [here](https://docs.digitalocean.com/reference/api/create-personal-access-token/) for more details.
- If you need to run this locally, uncomment the variables below in the `terraform.tfvars` file and populate with the required values
    - `digitalocean_token`
```
📑  The variables volume_size and volume_name can only be configured if you plan to run the Forest Mainnet Infrastructure.
```

- Set all necessary environment variables to the terminal permanently by adding them to a shell profile.
    - `export AWS_SECRET_ACCESS_KEY="value"`,
    - `export AWS_ACCESS_KEY_ID="value"`,

Then save the file and restart the terminal for the changes to take effect.

- Setup ssh-agent locally to allow ansible to locate the private key by running the following:
    - eval `ssh-agent`
    - `ssh-add <location to ssh key>`

- Navigate to the terraform directory and run `make init_calib` for calibnet and `make init_main` for mainnet to initialize and confirm variables.

- To view all the resources that will be configured, run `make plan_calib` for calibnet and `make plan_main` for mainnet still in the same terraform directory.

- To create the infrastructure, run `make apply_calib` for calibnet and `make apply_main` for mainnet in the terraform directory.

## Collaborators
Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases, or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to reach out to the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on how to interact with the infrastructure if the need arises while in deployment.
