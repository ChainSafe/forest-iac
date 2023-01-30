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

## Architectural Implementation

![Untitled Diagram drawio (8)](https://user-images.githubusercontent.com/47984109/215227510-dac5b8fb-8019-4388-a0e7-d5c432b95d70.png)

The flow goes from Terraform for provisioning of the servers and Anisble to run all neccessary installations including forest.

## Requirements 
- RAM: 32GB
- VCPU: 8
- Startup Disk Size: 100 GB
- Expected Total Disk Size: >500 GB

N/B: It's worth to note that some of the naming conventions can be changed to suit your deployment needs. 

To test out the implementation, just access the server with appropiate `ssh` details in this manner `ssh -i ~/id_rsa chainsafe@ip_address`.

## Collaborators
- [YOUR NAME HERE] - Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to reach out to the BlockOps team for more details on how to interact with the infrastructure if the need arises while in deployment.
