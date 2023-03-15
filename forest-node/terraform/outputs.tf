output "ip" {
  description = "output of created droplets"
  value = [digitalocean_droplet.forest_mainnet.ipv4_address, digitalocean_droplet.forest_observability.ipv4_address]
}
