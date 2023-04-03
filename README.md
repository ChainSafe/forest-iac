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
- Populate the `terraform.tfvars` file with the values of the following
    - `new_key_ssh_key_fingerprint`
    - `digitalocean_token`
    - `name`
    - `observability_name`
    - `volume_size`
    - `Volume_name`

```
📑  The variables volume_size and volume_name can only be configured if you plan to run Forest Mainnet Infrastructure.
```

- Set all necessary environment variables to the terminal permanently by adding them to a shell profile.
    - `export AWS_SECRET_ACCESS_KEY="value"`,
    - `export AWS_ACCESS_KEY_ID="value"`,

Then save the file and restart the terminal for the changes to take effect.

- Setup ssh-agent locally to allow ansible to locate the private key by running the following:
    - eval `ssh-agent`
    - `ssh-add <location to ssh key>`

- Navigate to the terraform directory and run `make init_calib` for calibnet or `make init_main` for mainnet to initialize and confirm variables.

- To view all the resources that will be configured, run `make plan_calib` for calibnet or `make plan_main` for mainnet in the terraform directory.

- To create the infrastructure, run `make apply_calib` for calibnet or `make apply_main` for mainnet in the terraform directory.

- Navigate to the ansible directory and run the command `make ping_calibnet` for calibnet or `make ping_main` for mainnet to verify the connection to the hosts.

- While in the ansible directory, run `make forest_calib` to initialize forest calibnet or `make forest_main` for forest mainnet.

## Observability

### Requirements
The droplet requirements to run observability for forest-calibnet include:
- RAM: 8GB
- VCPU: 1
- Disk Size: >100 GB

To configure Observability which includes `Prometheus`, `alertmanager`, `Loki`, `Node Exporter`, `Grafana` and `HTTPS` the following variables are available to be used according to your needs and should be filled in the `observability.yaml` and `letsencrypt.yaml` file.

| Variable   	                            | Description                                       | Default Value |
|-------------------------------------------|---------------------------------------------------|---------------|
| node\_exporter\_version                            | Node Exporter version to be Installed                          | 1.1.2        |
| docker\_compose\_version                             | Docker Compose Version to be Installed                          | v2.16.0        |
| prometheus\_retention\_time                                | Premetheus Metrics Retention time                         | 365 Days     |
| prometheus\_scrape\_interval                                | How Frequently Should Prometheus Scrape metrics                           | 30s          |
| slack\_api\_url                               | Slack Webhooks Url                          | "" [Required]()          |
| slack\_channel                              | Slack Channel to Receive Alert Manager Notifications                            | "" [Required]()           |
| loki\_from\_date                          | The Start of The Database Schema Version   | 2022-01-01    |
| loki\_schema\_version                     | Which Database Schema Version to use              | v11           |
| spaces\_endpoint                       | Digital Ocean Spaces Endpoint                                        | nyc3.digitaloceanspaces.com         |
| spaces\_region                          | Spaces Bucket Region                                  | nyc3     |
| spaces\_bucket\_name                          | Digital Ocean S3 Compatible Spaces Name                                    |   "" [Required]()          |
| spaces\_access\_token                    | Spaces Access key Token                                   | "" [Required]()     |
|  spaces_secret_key     | Spaces Secret Access key                   | "" [Required]()           |
| loki\_ingester\_chunk\_idle\_period   | Flush the chunk after time idle                      | 5m          |
| volume_name   |  Digital Ocean Volume Name For Mainnet Data                     | "" [Required, when running Mainnet]()         |
| domain_name   |    Custom Domain Name for the Grafana Endpoint                   | "" [Required]()         |
| letsencrypt_email   |   Email to be Used when Request for HTTPS certificate                   | "" [Required In the Lets Encrypt Yaml]()         |

- In the ansible directory, run `make observ_calib` for calibnet or `make observ_main` for mainnet to start configuring the required services, including `Grafana Loki`, `Prometheus`, `Node Exporter`, and `Alertmanager`.

- Before initializing HTTPS with Let's Encrypt, ensure that you have mapped the Observability Droplet IP to your custom domain. Once you have completed this step, run  `make lets_calib` for Calibnet or `make lets_main` for Mainnet in the ansible directory.

- Once the observability stack is up, you can access your Grafana UI here `https://example.com` depending on the pre-defined domain name. Use the default Grafana credentials: `admin:admin`.

- To query the Loki logs, go to the Grafana webapp's `Configuration/Data Sources` section, select Loki, click explore, and then run LogQL queries. For more information on `LogQL`, see its documentation [here](https://grafana.com/docs/loki/latest/logql/). There are two folders in the space; `fake` and `index`, while fake stores the main log data and index store the metadata of the chunks.

Also, be aware that after ansible has configured all services, the servers will only be accessible via the `chainsafe` user which can be changed in `ansible.cfg` file if required. To test this implementation, access the server with appropriate `ssh` details in this format `ssh -i ~/.ssh/id_rsa chainsafe@ip_address`.

## Collaborators
Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases, or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to reach out to the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on how to interact with the infrastructure if the need arises while in deployment.
