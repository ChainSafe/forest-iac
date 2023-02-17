
## Running Forest In DigitalOcean

## Forest IAC Architectue

![Forest Cloud Infrastructure ](https://user-images.githubusercontent.com/47984109/216006502-eca661d3-2ef8-4c75-aa7a-1740c25abb44.png)

## Requirements 
- RAM: 32GB
- VCPU: 8
- Startup Disk Size: 200 GB
- Expected Total Disk Size: > 500 GB
- Docker-image based VM
- SSH Key should be created locally using `ssh keygen` then added into digitalocean console where the fingerprint can be generated and added as a variable while creation the droplet. 

N/B: It's worth noting that the naming conventions can be changed to suit your deployment needs especially the names for the resource blocks. In this case; `new-key-name`, `spaces-name`, `forest`, `forest-firewalls-test`, and `hosts`.

To test this implementation, access the server with appropriate `ssh` details in this manner `ssh -i ~/.ssh/id_rsa chainsafe@ip_address`. However, if you intend to use another `user` other than `chainsafe`, then this can be changed in the Ansible main playbook. Avoid running Forest as `root`.  

In order to implement the infrastructure, run the following:
- In order to fully explore the IAC functionalities, it is required to have a `*.tfvars` file. This will be in con junction with the variables specified in `varaible.tf`. The format for the `*.tfvars` file is shown below:
    - image = "docker-20-04"
    - size = "so-4vcpu-32gb"
    - name = "forest"
As soon as the file is created and the content added then the terraform file structure is complete. However, be aware that the gitignore file will ignore that file so it does not become public when sent to any source code repository. 
- Create a space on Digitalocean with any preferred unique name. 
- Install s3cmd via the following steps:
    - RedHat: `sudo dnf install s3cmd`
    - Ubuntu: `sudo apt-get install s3cmd`
    - MacOS: `brew install s3cmd`
- Confirm s3cmd installation with this command `s3cmd --configure`
- Set-up s3cmd 2.x with DigitalOcean Spaces; you can check [here](https://docs.digitalocean.com/products/spaces/reference/s3cmd/) for more details. This will require `ACCESS_TOKEN` and `SECRET_KEY`; it can be auto-generated from the DigitalOcean console through the Applications & API section.   
- Add all necessary environment variables by running `export SPACES_ACCESS_TOKEN="value"` and `export SPACES_SECRET_KEY="value"`, while using the values generated in the previous step.
- Run `make plan` in the terraform directory.   
- Run `make apply` in the terraform directory to create the infrastructure and update the ansible hosts file with the IP address. 
- Run `ansible all -m ping` to confirm connection to hosts.  
- Run `ansible-playbook forest.yaml` in the ansible directory to initialize forest.

Also, be aware that after ansible has configured all services, the servers will only be accessible via the `chainsafe` user which can be changed in `ansible.cfg` file if required. 

## Collaborators
Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases, or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to reach out to the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on how to interact with the infrastructure if the need arises while in deployment.
