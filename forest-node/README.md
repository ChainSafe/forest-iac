
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
- Create a slack app needed for the setup by following the instructions [here](https://api.slack.com/apps?new_app=1).


Also, be aware that after ansible has configured all services, the servers will only be accessible via the `chainsafe` user which can be changed in `ansible.cfg` file if required. To test this implementation, access the server with appropriate `ssh` details in this format `ssh -i ~/.ssh/id_rsa chainsafe@ip_address`. 

In order to implement the infrastructure, run the following:
- Set-up s3cmd 2.x with DigitalOcean Spaces; you can check [here](https://docs.digitalocean.com/products/spaces/reference/s3cmd/) for more details. This will require `ACCESS_TOKEN` and `SECRET_KEY`; it can be auto-generated from the DigitalOcean console through the Applications & API section.   
- Add all necessary environment variables by running `echo $SPACES_ACCESS_TOKEN` and `echo $SPACES_SECRET_KEY` while using the values generated in the previous step.
- Create a `*.tfvars` file to use the necessary variable values for terraform running success. Also, be aware that the `keys_name` must be unique. 
- Setup ssh-agent locally to allow ansible locate the private key by running the following:
    - `eval ssh-agent`
    - `ssh-add <location to ssh key>`
- Run `make plan` in thr terraform directory.   
- Run `make apply` in the terraform directory to create the infrastructure and update the ansible hosts file with the IP address. 
- Run `ansible all -m ping` to confirm connection to hosts.  
- Run `ansible-playbook forest.yaml` in the ansible directory to initialize forest.

## Observability 
- In the ansible directory, to set-up observability stacks for your forest node, in the `observability.yaml` yaml. Set `slack api url` and slack `channel` to the slack webhook url and channel you obtained from the requirements, and then run `ansible-playbook observability.yaml`.

To configure Observability which includes `Prometheus`, `alertmanager`, `Loki`, `Node Exporter` and `Grafana`, the following variables are available to be used according to your needs

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

- In the `observability.yaml` file, define all the values for the `slack_api_url`, `channel`, `spaces_access_token`, `spaces_bucket_name` and `spaces_secret_key` as it is in your setup. 
- Then, run `ansible-playbook observability.yaml` for ansible to start configuring all the required services. This will set up observability stack with `Grafana Loki`, `Prometheus`, `Node Exporter` and `Alertmanager`. Once the observability stack is running, you can access your Grafana UI `http://<observability-droplet-ip>:3000` to view the predefined dashboards. Use the default Grafana credentials: `admin/admin`.

- To query the Loki logs, go to the Grafana webapp's `Configuration/Data Sources` section, select Loki, click on Explore, and then run LogQL queries. The logs will also be stored on the `spaces buckets` as defined in `terraform.tfvars` for long-term log storage. For more information on `LogQL`, see its [documentation](https://grafana.com/docs/loki/latest/logql/). There are two folders in the space; `fake` and `index` - fake stores the main log data and index stores the metadata of the chunks. 

Also, be aware that after ansible has configured all services, the servers will only be accessible via the `chainsafe` user which can be changed in `ansible.cfg` file if required. To test this implementation, access the server with appropriate `ssh` details in this format `ssh -i ~/.ssh/id_rsa chainsafe@ip_address`.   

## Collaborators
Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases, or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to reach out to the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on how to interact with the infrastructure if the need arises while in deployment.
