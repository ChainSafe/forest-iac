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
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
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

resource "digitalocean_volume" "forest_storage" {
  region                  = "fra1"
  name                    = "snapshot-gen-storage"
  size                    = 400
  initial_filesystem_type = "ext4"
  description             = "DB storage for snapshot generation"
}

resource "digitalocean_droplet" "forest" {
  image  = var.image
  name   = var.name
  region = var.region
  size   = var.size
  # Re-initialize resource if this hash changes:
  user_data = data.local_file.sources.content_sha256
  tags      = ["iac"]
  ssh_keys  = data.digitalocean_ssh_keys.keys.ssh_keys.*.fingerprint

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

  # WARNING: Changing these commands will _not_ trigger a re-deployment. If you
  # edit these commands, you'll have to re-deploy manually.
  provisioner "remote-exec" {
    inline = [
      "cd /root/",
      "tar xf sources.tar",
      # Set required environment variables
      "echo 'export AWS_ACCESS_KEY_ID=\"${var.AWS_ACCESS_KEY_ID}\"' >> .bashrc",
      "echo 'export AWS_SECRET_ACCESS_KEY=\"${var.AWS_SECRET_ACCESS_KEY}\"' >> .bashrc",
      "echo 'export SLACK_API_TOKEN=\"${var.slack_token}\"' >> .bashrc",
      "echo 'export SLACK_NOTIF_CHANNEL=\"${var.slack_channel}\"' >> .bashrc",
      "echo 'export SNAPSHOT_BUCKET=\"${var.snapshot_bucket}\"' >> .bashrc",
      "echo 'export SNAPSHOT_ENDPOINT=\"${var.snapshot_endpoint}\"' >> .bashrc",
      "echo 'export BASE_FOLDER=\"/root\"' >> .bashrc",
      "echo 'export FOREST_TAG=\"latest\"' >> .bashrc",
      "source ~/.bashrc",
      "./init.sh"
    ]
  }
}

resource "digitalocean_volume_attachment" "attach_forest_storage" {
  droplet_id = digitalocean_droplet.forest.id
  volume_id  = digitalocean_volume.forest_storage.id
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

resource "digitalocean_firewall" "forest-firewall" {
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
