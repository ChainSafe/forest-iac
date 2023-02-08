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

resource "digitalocean_volume" "forest-volume" {
  region                  = var.region
  name                    = var.volume_name
  size                    = var.volume_size 
  initial_filesystem_type = var.initial_filesystem_type
  description             = var.description 
}

resource "digitalocean_volume" "lotus-volume" {
  region                  = var.region
  name                    = var.volume_name_l
  size                    = var.volume_size 
  initial_filesystem_type = var.initial_filesystem_type
  description             = var.description 
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

resource "digitalocean_droplet" "lotus" {
  image  = var.image
  name   = var.l-name
  region = var.region
  size   = var.l-size
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

resource "digitalocean_volume_attachment" "lotus-volume" {
  droplet_id = digitalocean_droplet.lotus.id
  volume_id  = digitalocean_volume.lotus-volume.id
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

droplet_ids = [digitalocean_droplet.forest.id, digitalocean_droplet.lotus.id]
}

output "ip" {
  value = [digitalocean_droplet.forest.ipv4_address, digitalocean_droplet.lotus.ipv4_address]
}

resource "local_file" "hosts" {
  content = templatefile("../ansible/hosts",
    {
      forest = digitalocean_droplet.forest.ipv4_address.*
      lotus = digitalocean_droplet.lotus.ipv4_address.*
    }
  )
  filename = "../ansible/hosts"
}
