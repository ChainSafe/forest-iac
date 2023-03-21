 resource "digitalocean_firewall" "forest_firewall" {
  name = var.name

  inbound_rule {
    protocol         = var.protocol
    port_range       = "22"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol         = var.protocol
    port_range       = "1234"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol           = var.protocol
    port_range         = "6116"
    source_droplet_ids = [digitalocean_droplet.forest_observability.id]
  }

  inbound_rule {
    protocol           = var.protocol
    port_range         = "9100"
    source_droplet_ids = [digitalocean_droplet.forest_observability.id]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  droplet_ids = [digitalocean_droplet.forest.id]
}

resource "digitalocean_firewall" "forest_observability_firewall" {
  name = var.observability_name

  inbound_rule {
    protocol         = var.protocol
    port_range       = "22"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol         = var.protocol
    port_range       = "80"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol         = var.protocol
    port_range       = "443"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol           = var.protocol
    port_range         = "3100"
    source_droplet_ids = [digitalocean_droplet.forest.id]
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

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = var.destination_addresses
  }

  droplet_ids = [digitalocean_droplet.forest_observability.id]
}
