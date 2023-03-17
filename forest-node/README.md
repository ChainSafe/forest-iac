
## Running Forest In DigitalOcean

## Forest IAC Architectue

![Forest Cloud Infrastructure ](https://user-images.githubusercontent.com/47984109/216006502-eca661d3-2ef8-4c75-aa7a-1740c25abb44.png)

## Requirements
The droplet requirements to run forest-calibnet include:
- RAM: 8GB
- VCPU: 1
- Disk Size: >100 GB

The user local machine requirements include:
- Install [Terraform](https://developer.hashicorp.com/terraform/downloads) and [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).
- Install `make`
- Basic DigitalOcean knowledge

In order to implement the infrastructure, run the following:
- Create `ssh-key` to be added to DigitalOcean list and store the fingerprint for use in the next few steps; you can check more details [here](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/to-team/)
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

## Observability

To configure Observability which includes `Prometheus`, `alertmanager`, `Loki`, `Node Exporter` and `Grafana`, the following variables are available to be used according to your needs and should be filled in the `observability.yaml` file.

| Variable   	                            | Description                                       | Default Value |
|-------------------------------------------|---------------------------------------------------|---------------|
| node\_exporter\_version                            | Node Exporter version to be installed                          | 1.1.2        |
| docker\_compose\_version                             | Docker Compose version to be installed                          | v2.16.0        |
| prometheus\_retention\_time                                | Premetheus metrics retention time                         | 365 Days     |
| prometheus\_scrape\_interval                                | How frequently should prometheus scrape metrics                           | 30s          |
| slack\_api\_url                               | Slack Webhooks url                          | "" [Required]()          |
| slack\_channel                              | Slack Channel to receive Alert Manager notifications                            | "" [Required]()           |
| loki\_from\_date                          | When did this database schema version started     | 2022-01-01    |
| loki\_schema\_version                     | Which database schema version to use              | v11           |
| spaces\_endpoint                       | Digital Ocean Spaces Endpoint                                        | nyc3.digitaloceanspaces.com         |
| spaces\_region                          | Spaces Bucket region                                  | nyc3     |
| spaces\_bucket\_name                          | Digital Ocean s3 compatible s3 Bucket name                                    |   Assigned by terraform as defined in the `terraform.tfvars`          |
| spaces\_access\_token                    | Spaces Access key Token                                   | "" [Required]()     |
|  spaces_secret_key     | Spaces Secret Access key                   | "" [Required]()           |
| loki\_ingester\_chunk\_idle\_period   | Flush the chunk after time idle                      | 5m          |

- Then, run `ansible-playbook observability.yaml` for ansible to start configuring all the required services. This will set up observability stack with `Grafana Loki`, `Prometheus`, `Node Exporter` and `Alertmanager`. Once the observability stack is running, you can access your Grafana UI `https://example.com` depending on the pre-defined domain name. Use the default Grafana credentials: `admin/admin`.

- While in the same directory, run `ansible-playbook letsencrypt.yaml` in the ansible directory to initialize letsencrypt.

- To query the Loki logs, go to the Grafana webapp's `Configuration/Data Sources` section, select Loki, click on Explore, and then run LogQL queries. The logs will also be stored on the `spaces buckets` as defined in `terraform.tfvars` for long-term log storage. For more information on `LogQL`, see its [documentation](https://grafana.com/docs/loki/latest/logql/). There are two folders in the space; `fake` and `index` - fake stores the main log data and index stores the metadata of the chunks.

Also, be aware that after ansible has configured all services, the servers will only be accessible via the `chainsafe` user which can be changed in `ansible.cfg` file if required. To test this implementation, access the server with appropriate `ssh` details in this format `ssh -i ~/.ssh/id_rsa chainsafe@ip_address`.

## Collaborators
Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases, or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to reach out to the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on how to interact with the infrastructure if the need arises while in deployment.
