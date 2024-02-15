resource "digitalocean_firewall" "forest_firewall" {
  name = format("%s-firewall", local.service_name)

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = var.rpc_port
    source_addresses = var.source_addresses
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
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


  // Outbound rule added to allow Network Time Protocol (NTP) traffic for time synchronization purposes.
  outbound_rule {
    protocol              = "udp"
    port_range            = "123"
    destination_addresses = var.destination_addresses
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = var.destination_addresses
  }

  droplet_ids = [digitalocean_droplet.forest.id]

  tags = [var.chain]
}
