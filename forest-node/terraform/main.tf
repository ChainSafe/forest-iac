terraform {
  required_version = "~> 1.3"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.1"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

resource "digitalocean_droplet" "forest" {
  image  = var.image
  name   = var.name
  region = var.region
  size   = var.size
  backups = var.backups
  ssh_keys = [var.new_key_ssh_key_fingerprint]

    lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_firewall" "forest-firewalls-test" {
  name = var.name

  inbound_rule {
    protocol              = "tcp"
    port_range            = "22"
    source_addresses      = var.source_addresses
  }

  inbound_rule {
    protocol              = "tcp"
    port_range            = "1234"
    source_addresses      = var.source_addresses
  }

  inbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    source_addresses      = var.source_addresses
  }

  inbound_rule {
    protocol              = "udp"
    port_range            = "53"
    source_addresses      = var.source_addresses
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

output "ip" {
  value = [digitalocean_droplet.forest.ipv4_address]
}

resource "local_file" "inventory" {
    filename = "../ansible/hosts"
    content     = <<_EOF
[forest]
${digitalocean_droplet.forest.ipv4_address}
    _EOF
}
