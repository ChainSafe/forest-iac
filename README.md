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

## Running Forest In DigitalOcean

## Forest IAC Architectue

![Forest Cloud Infrastructure ](https://user-images.githubusercontent.com/47984109/216006502-eca661d3-2ef8-4c75-aa7a-1740c25abb44.png)

The flow goes from Terraform for provisioning of the servers and Anisble to run all neccessary installations including forest.

## Requirements 
- RAM: 32GB
- VCPU: 8
- Startup Disk Size: 200 GB
- Expected Total Disk Size: > 500 GB

N/B: It's worth to note that most of the naming conventions can be changed to suit your deployment needs especially the names for the resource blocks. In this case; `forest-volume`, `new-key-name`,`spaces-name`,`forest-volume`, `forest`, `forest-firewalls-test` and `hosts`.

To test out the implementation, just access the server with appropiate `ssh` details in this manner `ssh -i ~/.ssh/id_rsa chainsafe@ip_address`. However, if you intend to use another `user` other than `chainsafe`, this can be switched in the Ansible main playbook, just avoid running forest as root.

In order ro implement the infrastructure, run the following:
- Set Up s3cmd 2.x with DigitalOcean Spaces; you can check [here](https://docs.digitalocean.com/products/spaces/reference/s3cmd/) on more details. This will require `ACCESS_TOKEN` and `SECRET_KEY` but it can be automatically generated from the DigitalOcean console through the Applications & API section.  
- Ensure to add all neccessary enviroment variables by running `echo $SPACES_ACCESS_TOKEN` and `echo $SPACES_SECRET_KEY` while using the values generated in the previous step.
- Create a `*.tfvars` file to use the neccessary variable values for terraform running success. Also, be aware that the `keys_name` must be unique.  
- Run `make apply` in the terraform directory.
- Run `ansible-playbook forest-docker-run.yaml` in the ansible directory.

## Collaborators
- Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to reach out to the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on how to interact with the infrastructure if the need arises while in deployment.
