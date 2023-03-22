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

resource "digitalocean_droplet" "forest_observability" {
  image    = var.image
  name     = var.observability_name
  region   = var.region
  size     = var.size
  backups  = var.backups
  ssh_keys = [var.new_key_ssh_key_fingerprint]

  lifecycle {
    create_before_destroy = true
  }
}

resource "local_file" "inventory" {
    filename = "../ansible/hosts"
    content     = <<_EOF
[forest]
${digitalocean_droplet.forest.ipv4_address}
[observability]
${digitalocean_droplet.forest_observability.ipv4_address}
    _EOF
}

output "ip" {
  description = "output of created droplets"
  value = [digitalocean_droplet.forest.ipv4_address, digitalocean_droplet.forest_observability.ipv4_address]
}
