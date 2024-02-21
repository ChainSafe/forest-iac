output "ip" {
  value = [digitalocean_droplet.forest.ipv4_address]
}
