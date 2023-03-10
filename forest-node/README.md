
## Running Forest In DigitalOcean

## Forest IAC Architecture

![Forest Cloud Infrastructure ](https://user-images.githubusercontent.com/47984109/219903795-77c306b8-a70b-4f32-8d7d-3c1a39e52186.jpg)

## Requirements
The droplet requirements to run forest-calibnet include:
- RAM: 8GB
- VCPU: 1
- Disk Size: 100 GB
The user local machine requirements include:
- Install [terraform](https://developer.hashicorp.com/terraform/downloads) and [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).
- Install `make`
- Basic DigitalOcean knowledge

To implement the infrastructure, run the following:
- Create `ssh-key` to be added to DigitalOcean list and store the fingerprint for use in the next step; you can check more details [here](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/to-team/)
- Create a space on DigitalOcean with any preferred unique name and add the bucket name and endpoint in the `backend.tf` file.
- Generate `digitalocean_api_token` from DigitalOcean console; you can check [here](https://docs.digitalocean.com/reference/api/create-personal-access-token/) for more details.
- Populate the `terraform.tfvars` file with the values of the following
    - `new_key_ssh_key_fingerprint`
    - `digitalocean_token`
    - `name`
- Set all necessary environment variables to the terminal permanently by adding them to a shell profile.
    - `export AWS_SECRET_ACCESS_KEY="value"`,
    - `export AWS_ACCESS_KEY_ID="value"`,
Then save the file and restart the terminal for the changes to take effect.
- Setup ssh-agent locally to allow ansible locate the private key by running the following:
    - eval `ssh-agent`
    - `ssh-add <location to ssh key>`
- Run `make init` in the terraform directory for initialization and variable confirmation.
- Run `make plan` in the terraform directory to view all the resources to be configured.
- Run `make apply` in the terraform directory to create the infrastructure.
- Move to the ansible directory and run `ansible all -m ping` to confirm connection to hosts.
- While in the same directory, run `ansible-playbook forest.yaml` in the ansible directory to initialize forest.

Also, be aware that after ansible has configured all services, the servers will only be accessible via the `chainsafe` user which can be changed in `ansible.cfg` file if required.

## Collaborators
Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases, or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to reach out to the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on how to interact with the infrastructure if the need arises while in deployment.
