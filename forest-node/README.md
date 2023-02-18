
## Running Forest In DigitalOcean

## Forest IAC Architecture

![Forest Cloud Infrastructure ](https://user-images.githubusercontent.com/47984109/219903795-77c306b8-a70b-4f32-8d7d-3c1a39e52186.jpg)

## Requirements  
- RAM: 32GB
- VCPU: 8
- Startup Disk Size: 200 GB
- Expected Total Disk Size: > 500 GB
- SSH Key should be created locally using `ssh keygen` and then added into digitalocean console where the fingerprint can be generated and added as a variable while creating the droplet.
- Install terraform and ansible.  
- Install `make`
- Basic digitalocean knowledge

To implement the infrastructure, run the following:
- Create `ssh-key` and store the fingerprint for use in the next step.
- To fully explore the IAC functionalities, it is required to have a `*.tfvars` file. This will be in conjunction with the variables specified in `varaible.tf`. The format for the `terraform.tfvars` file is shown below:
    ```
    image = "docker-20-04"
    size = "so-4vcpu-32gb"
    name = "forest"
    new_key_ssh_key_fingerprint = ""
    source_addresses = ["0.0.0.0/0", "::/0"]
    destination_addresses = ["0.0.0.0/0", "::/0"]
    firewall_name = ""
    digitalocean_token = ""
    region = ""
    ```
Be sure to update the values with preferred names for each of the empty parameters above. As soon as the file is created and the content added, then the terraform file structure is complete. However, be aware that the `gitignore` file will ignore that file so it does not become public when interacting with the source code repository. 
- Create a space on Digitalocean with any preferred unique name and add the bucket name in the `backend.tf` file. 
- Install `s3cmd` via the following steps depending on your OS:
    - RedHat: `sudo dnf install s3cmd`
    - Ubuntu: `sudo apt-get install s3cmd`
    - MacOS: `brew install s3cmd`
    - Windows: Follow the instructions [here](https://www.s3express.com/download.htm) 
- After installation then configure `s3cmd` with this command `s3cmd --configure`
- Confirm `s3cmd` installation with this command `s3cmd --version`
- Set-up `s3cmd` 2.x with DigitalOcean Spaces; you can check [here](https://docs.digitalocean.com/products/spaces/reference/s3cmd/) for proper details. This will require `ACCESS_TOKEN` and `SECRET_KEY` and it can be auto-generated from the DigitalOcean console through the Applications & API section.   
- Generate `digitalocean_api_token` from Digitalocean console; you can check [here](https://docs.digitalocean.com/reference/api/create-personal-access-token/) for more details. Additionally, the value should be added as a variable in the `terraform.tfvars` file when setting up the terraform directory. 
- Run `make init` in the terraform directory for initialization and variable confirmation.  
- Run `make plan` in the terraform directory to view all the resources to be configured.   
- Run `make apply` in the terraform directory to create the infrastructure and update the ansible hosts file with the right IP address. 
- Move to the ansible directory and run `ansible all -m ping` to confirm connection to hosts.  
- While in the same directory, run `ansible-playbook forest.yaml` in the ansible directory to initialize forest.

Also, be aware that after ansible has configured all services, the servers will only be accessible via the `chainsafe` user which can be changed in `ansible.cfg` file if required. To test this implementation, access the server with appropriate `ssh` details in this format `ssh -i ~/.ssh/id_rsa chainsafe@ip_address`.   

## Collaborators
Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases, or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to reach out to the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on how to interact with the infrastructure if the need arises while in deployment.
