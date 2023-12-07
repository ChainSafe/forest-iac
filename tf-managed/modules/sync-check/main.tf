# This terraform script executes the following steps:
#  - Zip the ruby and shell script files (the hash of this zip file is used to
#    determine when to re-deploy the service)
#  - Boot a new droplet
#  - Copy over the zip file
#  - Run calibnet and mainnet sync check in the background

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
  program = ["sh", "${path.module}/prep_sources.sh", path.module, var.common_resources_dir]
}

data "local_file" "sources" {
  filename = data.external.sources_tar.result.path
}

// Note: The init.sh file is also included in the sources.zip such that the hash
// of the archive captures the entire state of the machine.
// This is a workaround, and because of this, we need to suppress the tflint warning here
// for unused declarations related to the 'init.sh' file.
// tflint-ignore: terraform_unused_declarations
data "local_file" "init" {
  filename = "${path.module}/service/init.sh"
}

data "digitalocean_ssh_keys" "keys" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

# Set required environment variables
locals {
  env_content = templatefile("${path.module}/service/forest-env.tpl", {
    FOREST_TARGET_DATA        = "/volumes/forest_data",
    FOREST_TARGET_SCRIPTS     = "/volumes/sync_check",
    FOREST_TARGET_RUBY_COMMON = "/volumes/ruby_common",
    slack_token               = var.slack_token,
    slack_channel             = var.slack_channel,
    NEW_RELIC_API_KEY         = var.NEW_RELIC_API_KEY,
    NEW_RELIC_ACCOUNT_ID      = var.NEW_RELIC_ACCOUNT_ID,
    NEW_RELIC_REGION          = var.NEW_RELIC_REGION,
    forest_tag                = "edge"
  })
}

locals {
  init_commands = [
    "tar xf sources.tar",
    # Set required environment variables
    "echo '${local.env_content}' >> /root/.forest_env",
    "echo '. ~/.forest_env' >> .bashrc",
    ". ~/.forest_env",
    "nohup sh ./init.sh > init_log.txt &",
    "cp ./restart.service /etc/systemd/system/",
    "systemctl enable restart.service",
    # Exiting without a sleep sometimes kills the script :-/
    "sleep 60s",
  ]
}

resource "digitalocean_droplet" "forest" {
  image  = var.image
  name   = var.name
  region = var.region
  size   = var.size
  # Re-initialize resource if this hash changes:
  user_data  = join("-", [data.local_file.sources.content_sha256, sha256(join("", local.init_commands))])
  tags       = ["iac"]
  ssh_keys   = data.digitalocean_ssh_keys.keys.ssh_keys[*].fingerprint
  monitoring = true

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

