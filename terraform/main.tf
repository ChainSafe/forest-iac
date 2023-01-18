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

resource "digitalocean_space" "forest" {
  name             = "forest"
  region           = "lon1"
}

resource "digitalocean_space_access_key" "forest" {
  space_id = digitalocean_space.forest.id
}

resource "digitalocean_secret" "forest" {
  name         = "forest"
  value        = "YOUR_SECRET_KEY"
}

resource "digitalocean_ssh_key" "samuel-ssh-key" {
  name       = "sam-ssh-key"
  public_key = file("~/.ssh/samuel.pub")
}

resource "digitalocean_volume" "forest-volume" {
  region                  = "lon1"
  name                    = "forest-volume"
  size                    = 600
  initial_filesystem_type = "ext4"
  description             = "forrst storage volume"
}

resource "digitalocean_droplet" "forest-samuel" {
  image  = var.image
  name   = var.name
  region = var.region
  size   = var.size
  backups = var.backups
  ssh_keys = [digitalocean_ssh_key.samuel-ssh-key.fingerprint]

  lifecycle {
    create_before_destroy = true
  }
  provisioner "file" {
    source = "./forest.conf"
    destination = "/etc/systemd/system/forest.service"

    connection {
      type = var.type
      user = var.user
      private_key = file("~/.ssh/samuel")
      host = self.ipv4_address
      agent = var.agent
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo systemctl start docker",
      "sudo git clone --recursive https://github.com/chainsafe/forest",
      "sudo docker run --init -it --rm --entrypoint forest-cli ghcr.io/chainsafe/forest:latest --help",
      "sudo docker run --init -it -v $HOME/Downloads:/downloads ghcr.io/chainsafe/forest:latest --encrypt-keystore false --import-snapshot /downloads/minimal_finality_stateroots_latest.car",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable forest.service",
      "sudo systemctl start forest.service",
    ]
    connection {
      type = var.type
      user = var.user
      private_key = file("~/.ssh/samuel")
      host = self.ipv4_address
      agent = var.agent
    }
  }
}

resource "digitalocean_volume_attachment" "forest-volume" {
  droplet_id = digitalocean_droplet.forest-samuel.id
  volume_id  = digitalocean_volume.forest-volume.id
}

resource "digitalocean_firewall" "forest" {
  name = "forest-firewall"

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