terraform {
  required_version = "~> 1.3.7"

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

variable "digitalocean_token" {}
variable "image" {}
variable "name" {}
variable "region" {}
variable "size" {}
variable "backups" {}
variable "type" {}
variable "user" {}
variable "agent" {}
variable "protocol" {}
variable "source_addresses" {}

resource "digitalocean_ssh_key" "sammy-key" {
  name       = "sammy-key"
  public_key = file("~/sammy.pub")
}

resource "digitalocean_volume" "forest-volu" {
  region                  = "lon1"
  name                    = "forest-volu"
  size                    = 600
  initial_filesystem_type = "ext4"
  description             = "forest storage volume"
}

resource "digitalocean_droplet" "forest-samuel" {
  image  = var.image
  name   = var.name
  region = var.region
  size   = var.size
  backups = var.backups
  ssh_keys = [digitalocean_ssh_key.sammy-key.fingerprint]

  lifecycle {
    create_before_destroy = true
  }
  provisioner "file" {
    source = "./forest.conf"
    destination = "/etc/systemd/system/forest.service"

    connection {
      type = var.type
      user = var.user
      private_key = file("~/sammy")
      host = self.ipv4_address
      agent = var.agent
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo apt-get update",
      "sudo git clone https://github.com/chainsafe/forest",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable forest.service",
      "docker run --init -it --detach -v $HOME/Downloads:/downloads ghcr.io/chainsafe/forest:latest --encrypt-keystore false --download-snapshot",
      "sudo systemctl start forest.service",
    ]
    connection {
      type = var.type
      user = var.user
      private_key = file("~/sammy")
      host = self.ipv4_address
      agent = var.agent
    }
  }
}

resource "digitalocean_volume_attachment" "forest-volume" {
  droplet_id = digitalocean_droplet.forest-samuel.id
  volume_id  = digitalocean_volume.forest-volu.id
}

resource "digitalocean_firewall" "forest-firewall-test" {
  name = "forest-firewall-test"

  inbound_rule {
    protocol = var.protocol
    port_range = "22"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol = var.protocol
    port_range = "80"
    source_addresses = var.source_addresses
  }
  droplet_ids = [digitalocean_droplet.forest-samuel.id]
}

output "ip" {
  value = digitalocean_droplet.forest-samuel.ipv4_address
}