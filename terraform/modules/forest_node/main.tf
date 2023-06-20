# This terraform script executes the following steps:
#  - Boot a New droplet for the Mainnet or Calibnet chain
#  - Attach a volume to the droplet if Attach volume is set to true
#  - Run the user-data.sh script at the initialization of the new droplet

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
  token = var.do_token
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
  image      = var.image
  name       = var.name
  region     = var.region
  size       = var.size
  ssh_keys   = data.digitalocean_ssh_keys.keys.ssh_keys.*.fingerprint
  monitoring = true

  user_data = templatefile("${path.module}/user-data.sh",
    {
      NEW_USER = "${var.name}"
      # In the filesystem on the droplet, certain special characters, including "-",
      # are not allowed in device identifiers for block storage volumes.
      # Therefore, any "-" characters in the volume name are replaced with "_" when forming the device ID.
      VOLUME_NAME          = "${var.attach_volume}" ? replace(var.volume_name, "-", "_") : ""
      CHAIN                = "${var.chain}"
      DISK_ID_VOLUME_NAME  = "${var.attach_volume}" ? var.volume_name : ""
      NR_LICENSE_KEY       = "${var.NR_LICENSE_KEY}"
      NEW_RELIC_API_KEY    = "${var.NEW_RELIC_API_KEY}"
      NEW_RELIC_ACCOUNT_ID = "${var.NEW_RELIC_ACCOUNT_ID}"

  })

  tags = [var.chain]
}


resource "digitalocean_volume" "forest_volume" {
  count = var.attach_volume ? 1 : 0

  region                  = var.region
  name                    = var.volume_name
  size                    = var.volume_size
  initial_filesystem_type = var.initial_filesystem_type

  tags = [var.chain]
}

resource "digitalocean_volume_attachment" "forest_volume" {
  count = var.attach_volume ? 1 : 0

  droplet_id = digitalocean_droplet.forest.id
  volume_id  = digitalocean_volume.forest_volume[count.index].id
}
