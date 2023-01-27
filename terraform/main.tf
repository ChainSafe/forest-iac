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

resource "digitalocean_volume" "forest-volum" {
  region                  = "nyc3"
  name                    = "forest-volum"
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
  ssh_keys = [var.sam_ssh_key_fingerprint, var.guillaume_ssh_key_fingerprint, var.hubert_ssh_key_fingerprint, var.david_ssh_key_fingerprint]

    lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_volume_attachment" "forest-volume" {
  droplet_id = digitalocean_droplet.forest-samuel.id
  volume_id  = digitalocean_volume.forest-volum.id
}

resource "digitalocean_firewall" "forest-firewalls-test" {
  name = "forest-firewalls-test"

  inbound_rule {
    protocol = var.protocol
    port_range = "22"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol = var.protocol
    port_range = "1234"
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