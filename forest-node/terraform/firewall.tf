 resource "digitalocean_firewall" "forest-firewall" {
  name = "forest-firewalls"

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
    source_droplet_ids = [digitalocean_droplet.forest-observability.id]
  }

  inbound_rule {
    protocol           = var.protocol
    port_range         = "9100"
    source_droplet_ids = [digitalocean_droplet.forest-observability.id]
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

resource "digitalocean_firewall" "forest-observability-firewall" {
  name = "forest-observability"

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
    port_range       = "3000"
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

  droplet_ids = [digitalocean_droplet.forest-observability.id]
}