
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
  token = var.digitalocean_token
}

// Ugly hack because 'archive_file' cannot mix files and folders.
data "external" "sources_zip" {
  program = ["sh", "${path.module}/prep_sources.sh", "${path.module}"]
}

data "local_file" "sources" {
  filename = data.external.sources_zip.result.path
}

// Note: The init.sh file is also included in the sources.zip such that the hash
// of the archive captures the entire state of the machine.
data "local_file" "init" {
  filename = "${path.module}/service/init.sh"
}

resource "digitalocean_droplet" "forest" {
  image  = var.image
  name   = var.name
  region = var.region
  size   = var.size
  # Re-initialize resource if this hash changes:
  user_data = data.local_file.sources.content_sha256
  tags      = ["iac"]
  ssh_keys  = [var.new_key_ssh_key_fingerprint]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
  }

  provisioner "file" {
    source      = data.local_file.sources.filename
    destination = "/root/sources.zip"
  }

  provisioner "file" {
    source      = data.local_file.init.filename
    destination = "/root/init.sh"
  }

  # WARNING: Changing these commands will _not_ trigger a re-deployment. If you
  # edit these commands, you'll have to re-deploy manually.
  provisioner "remote-exec" {
    inline = [
      "cd /root/",
      # Set required environment variables
      "export AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY_ID}",
      "export AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_ACCESS_KEY}",
      "export SLACK_API_TOKEN=${var.slack_token}",
      "export SLACK_NOTIF_CHANNEL=${var.slack_channel}",
      # Run init script in the background
      "nohup sh ./init.sh ${var.chain} &",
      "sleep 10s",
    ]
  }
}

data "digitalocean_project" "forest_project" {
  name = var.project
}

resource "digitalocean_project_resources" "connect_forest_project" {
  project   = data.digitalocean_project.forest_project.id
  resources = [digitalocean_droplet.forest.urn]
}

resource "digitalocean_firewall" "forest-firewalls-test" {
  name = var.name

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "1234"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "53"
    source_addresses = var.source_addresses
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = var.destination_addresses
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = var.destination_addresses
  }

  droplet_ids = [digitalocean_droplet.forest.id]
}

# This ip address may be used in the future by monitoring software
output "ip" {
  value = [digitalocean_droplet.forest.ipv4_address]
}
