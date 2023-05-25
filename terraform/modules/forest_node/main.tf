terraform {
  required_version = "~> 1.3"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

data "digitalocean_ssh_keys" "keys" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

data "digitalocean_project" "forest_project" {
  name = var.project
}

resource "digitalocean_project_resources" "connect_forest_project" {
  project   = data.digitalocean_project.forest_project.id
  resources = [digitalocean_droplet.forest.urn]
}

resource "digitalocean_droplet" "forest" {
  image    = var.image
  name     = var.name
  region   = var.region
  size     = var.size
  ssh_keys = data.digitalocean_ssh_keys.keys.ssh_keys.*.fingerprint

  user_data = templatefile("${path.module}/user-data.tpl",
  {
    NEW_USER    = "${var.name}"
    VOLUME_NAME = "${var.attach_volume}" ? replace(var.volume_name, "-", "_") : ""
  })

  tags = [var.enviroment]
}


resource "digitalocean_volume" "forest_volume" {
  count = var.attach_volume ? 1 : 0

  region                  = var.region
  name                    = var.volume_name
  size                    = var.volume_size
  initial_filesystem_type = var.initial_filesystem_type

  tags = [var.enviroment]
}

resource "digitalocean_volume_attachment" "forest_volume" {
  count = var.attach_volume ? 1 : 0

  droplet_id = digitalocean_droplet.forest.id
  volume_id  = digitalocean_volume.forest_volume[count.index].id
}
