locals {
  /// CIDR for all IPv4 and all IPv6 addresses
  any_address = ["0.0.0.0/0", "::/0"]
}

resource "digitalocean_firewall" "forest_firewall" {
  name        = format("%s-firewall", local.droplet_name)
  droplet_ids = [digitalocean_droplet.forest.id]

  dynamic "inbound_rule" {
    for_each = [
      "22",    // SSH
      "2345",  // RPC
      "6116",  // Metrics
      "80",    // HTTP
      "12345", // P2P
    ]
    iterator = port
    content {
      protocol         = "tcp"
      port_range       = port.value
      source_addresses = local.any_address
    }
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = local.any_address
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53" // DNS
    destination_addresses = local.any_address
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "123" // NTP
    destination_addresses = local.any_address
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = local.any_address
  }

}
