# This terraform script executes the following steps:
#  - Zip the ruby and shell script files (the hash of this zip file is used to
#    determine when to re-deploy the service)
#  - Boot a new droplet
#  - Copy over the zip file
#  - Run the init.sh script in the background

terraform {
  required_version = "~> 1.3"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }

  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

// Ugly hack because 'archive_file' cannot mix files and folders.
data "external" "sources_tar" {
  program = ["sh", "${path.module}/prep_sources.sh", path.module]
}

data "local_file" "sources" {
  filename = data.external.sources_tar.result.path
}

data "digitalocean_ssh_keys" "keys" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

locals {
  init_commands = ["cd /root/",
    "tar xf sources.tar",
    # Set required environment variables
    "echo 'export AWS_ACCESS_KEY_ID=\"${var.AWS_ACCESS_KEY_ID}\"' >> .forest_env",
    "echo 'export AWS_SECRET_ACCESS_KEY=\"${var.AWS_SECRET_ACCESS_KEY}\"' >> .forest_env",
    "echo 'export SLACK_API_TOKEN=\"${var.slack_token}\"' >> .forest_env",
    "echo 'export SLACK_NOTIF_CHANNEL=\"${var.slack_channel}\"' >> .forest_env",
    "echo 'export BENCHMARK_BUCKET=\"${var.benchmark_bucket}\"' >> .forest_env",
    "echo 'export BENCHMARK_ENDPOINT=\"${var.benchmark_endpoint}\"' >> .forest_env",
    "echo 'export BASE_FOLDER=\"/chainsafe\"' >> .forest_env",
    "echo 'source .forest_env' >> .bashrc",
    "source ~/.forest_env",
    "nohup sh ./init.sh > init_log.txt &",
    # Exiting without a sleep sometimes kills the script :-/
    "sleep 10s"
  ]
}

resource "digitalocean_droplet" "forest" {
  image  = var.image
  name   = var.name
  region = var.region
  size   = var.size
  # Re-initialize resource if this hash changes:
  user_data = join("-", [data.local_file.sources.content_sha256, sha256(join("", local.init_commands))])
  tags      = ["iac"]
  ssh_keys  = data.digitalocean_ssh_keys.keys.ssh_keys[*].fingerprint

  graceful_shutdown = false

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
  }

  # Push the sources.tar file to the newly booted droplet
  provisioner "file" {
    source      = data.local_file.sources.filename
    destination = "/root/sources.tar"
  }

  provisioner "remote-exec" {
    inline = local.init_commands
  }
}

data "digitalocean_project" "forest_project" {
  name = var.project
}

# Connect the droplet to the forest project (otherwise it ends up in
# "ChainBridge" which is the default project)
resource "digitalocean_project_resources" "connect_forest_project" {
  project   = data.digitalocean_project.forest_project.id
  resources = [digitalocean_droplet.forest.urn]
}

# This ip address may be used in the future by monitoring software
output "ip" {
  value = [digitalocean_droplet.forest.ipv4_address]
}
