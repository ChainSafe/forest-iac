resource "digitalocean_firewall" "forest-firewall" {
  name = format("%s-%s", var.environment, var.name)

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "2345"
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

  # NTP
  outbound_rule {
    protocol              = "udp"
    port_range            = "123"
    destination_addresses = var.destination_addresses
  }

  droplet_ids = [digitalocean_droplet.forest.id]
}
