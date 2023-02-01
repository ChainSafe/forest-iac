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

resource "digitalocean_ssh_key" "new-key-name" {
  name       = "var.keys_name"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "digitalocean_spaces_bucket" "spaces-name" {
  name   = var.spaces_name
  region = var.region
}

resource "digitalocean_volume" "forest-volume" {
  region                  = var.region
  name                    = var.volume_name
  size                    = var.volume_size 
  initial_filesystem_type = var.initial_filesystem_type
  description             = "forest storage volume"
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

resource "digitalocean_volume_attachment" "forest-volume" {
  droplet_id = digitalocean_droplet.forest.id
  volume_id  = digitalocean_volume.forest-volume.id
}

resource "digitalocean_firewall" "forest-firewalls-test" {
  name = var.firewall_name

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

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = var.destination_addresses
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = var.destination_addresses
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = var.destination_addresses
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    destination_addresses = var.destination_addresses
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = var.destination_addresses
  }

droplet_ids = [digitalocean_droplet.forest.id]
}

output "ip" {
  value = digitalocean_droplet.forest.ipv4_address
}

resource "local_file" "hosts" {
  content = templatefile("../../ansible/hosts",
    {
      testing   = digitalocean_droplet.forest.ipv4_address
    }
  )
  filename = "../ansible/hosts"
}