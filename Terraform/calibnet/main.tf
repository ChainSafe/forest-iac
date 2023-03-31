terraform {
  required_version = ">= 1.3"

  backend "s3" {
    bucket                      = "forest-test-state"
    key                         = "terraform.tfstate"
    region                      = "us-west-1"
    endpoint                    = "nyc3.digitaloceanspaces.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

module "calibnet" {
  source = "../modules/forest_node"

  digitalocean_token = var.digitalocean_token
  name               = var.name
  region             = var.region
  backups            = var.backups
  image              = var.image
  size               = var.size
  observability_name = var.observability_name
  protocol           = var.protocol
  source_addresses   = var.source_addresses
  attach_volume      = false
  ssh_key            = var.ssh_key
  destination_addresses = var.destination_addresses
  enviroment         = var.enviroment
}
