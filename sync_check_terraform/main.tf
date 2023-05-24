terraform {
  backend "s3" {
    # Note: This is the bucket for the internal terraform state. This bucket is
    # completely independent from the bucket that contains snapshots.
    bucket = "forest-iac"
    # This key uniquely identifies the service. To create a new service (instead
    # of modifying this one), use a new key. Unfortunately, variables may not be
    # used here.
    key = "sync_check.tfstate"

    # This value is completely unused by DO but _must_ be a known AWS region.
    region = "us-west-1"
    # The S3 region is determined by the endpoint. fra1 = Frankfurt.
    # This region does not have to be shared by the droplet.
    endpoint = "https://fra1.digitaloceanspaces.com"

    # Credentially can be validated through the Security Token Service (STS).
    # Unfortunately, DigitalOcean does not support STS so we have to skip the
    # validation.
    skip_credentials_validation = "true"
  }
}

locals {
  name                  = "forest-sync-check" # droplet name
  size                  = "so-2vcpu-16gb"     # droplet size
  image                 = "fedora-36-x64"
  slack_channel         = "#forest-notifications" # slack channel for notifications
  region                = "fra1"
  source_addresses      = ["0.0.0.0/0", "::/0"]
  destination_addresses = ["0.0.0.0/0", "::/0"]
  project               = "Forest-DEV"

  # Variable passthrough:
  slack_token        = var.slack_token
  digitalocean_token = var.do_token
}

terraform {
  required_version = "~> 1.3"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

// Ugly hack because 'archive_file' cannot mix files and folders.
data "external" "sources_tar" {
  program = ["sh", "${path.module}/prep_sources.sh", "${path.module}"]
}

data "local_file" "sources" {
  filename = data.external.sources_tar.result.path
}

// Note: The init.sh file is also included in the sources.zip such that the hash
// of the archive captures the entire state of the machine.
data "local_file" "init" {
  filename = "${path.module}/service/init.sh"
}

data "digitalocean_ssh_keys" "keys" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

resource "digitalocean_droplet" "forest" {
  image  = local.image
  name   = local.name
  region = local.region
  size   = local.size
  # Re-initialize resource if this hash changes:
  user_data = data.local_file.sources.content_sha256
  tags      = ["iac"]
  ssh_keys  = data.digitalocean_ssh_keys.keys.ssh_keys.*.fingerprint

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
    inline = [
      "tar xf sources.tar",
      # Set required environment variables
      "echo 'export FOREST_TAG=edge' >> .forest_env",
      "echo 'export FOREST_TARGET_DATA=/volumes/forest_data' >> .forest_env",
      "echo 'export FOREST_TARGET_SCRIPTS=/volumes/sync_check' >> .forest_env",
      "echo 'export FOREST_TARGET_RUBY_COMMON=/volumes/ruby_common' >> .forest_env",
      "echo 'export FOREST_SLACK_API_TOKEN=\"${var.slack_token}\"' >> .forest_env",
      "echo 'export FOREST_SLACK_NOTIF_CHANNEL=\"${local.slack_channel}\"' >> .forest_env",
      "echo 'source .forest_env' >> .bashrc",
      "/bin/bash ./init.sh > init_log.txt",
      "nohup /bin/bash ./run_service.sh > run_service_log.txt &",
      "cp ./restart.service /etc/systemd/system/",
      "systemctl enable restart.service",
      # Exiting without a sleep sometimes kills the script :-/
      "sleep 10s",
    ]
  }
}

data "digitalocean_project" "forest_project" {
  name = local.project
}

# Connect the droplet to the forest project (otherwise it ends up in
# "ChainBridge" which is the default project)
resource "digitalocean_project_resources" "connect_forest_project" {
  project   = data.digitalocean_project.forest_project.id
  resources = [digitalocean_droplet.forest.urn]
}

resource "digitalocean_firewall" "forest-firewall" {
  name = local.name

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = local.source_addresses
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "1234"
    source_addresses = local.source_addresses
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = local.source_addresses
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "53"
    source_addresses = local.source_addresses
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = local.destination_addresses
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = local.destination_addresses
  }

  droplet_ids = [digitalocean_droplet.forest.id]
}

# This ip address may be used in the future by monitoring software
output "ip" {
  value = [digitalocean_droplet.forest.ipv4_address]
}
