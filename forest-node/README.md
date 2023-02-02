
## Running Forest In DigitalOcean

## Forest IAC Architectue

![Forest Cloud Infrastructure ](https://user-images.githubusercontent.com/47984109/216006502-eca661d3-2ef8-4c75-aa7a-1740c25abb44.png)

The flow goes from Terraform for provisioning of the servers and Anisble to run all neccessary installations including forest.

## Requirements 
- RAM: 32GB
- VCPU: 8
- Startup Disk Size: 200 GB
- Expected Total Disk Size: > 500 GB

N/B: It's worth noting that the naming conventions can be changed to suit your deployment needs especially the names for the resource blocks. In this case; `forest-volume`, `new-key-name`, `spaces-name`, `forest-volume`, `forest`, `forest-firewalls-test`, and `hosts`.

To test this implementation, access the server with appropriate `ssh` details in this manner `ssh -i ~/.ssh/id_rsa chainsafe@ip_address`. However, if you intend to use another `user` other than `chainsafe`, then this can be switched in the Ansible main playbook. Avoid running Forest as `root`.  

In order to implement the infrastructure, run the following:
- Set-up s3cmd 2.x with DigitalOcean Spaces; you can check [here](https://docs.digitalocean.com/products/spaces/reference/s3cmd/) for more details. This will require `ACCESS_TOKEN` and `SECRET_KEY`; it can be auto-generated from the DigitalOcean console through the Applications & API section.   
- Add all necessary environment variables by running `echo $SPACES_ACCESS_TOKEN` and `echo $SPACES_SECRET_KEY` while using the values generated in the previous step.
- Create a `*.tfvars` file to use the necessary variable values for terraform running success. Also, be aware that the `keys_name` must be unique.    
- Run `make apply` in the terraform directory.
- Run `ansible-playbook forest-docker-run.yaml` in the ansible directory.

## Collaborators
Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases, or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to reach out to the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on how to interact with the infrastructure if the need arises while in deployment.