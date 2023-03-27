

terraform {
  required_version = ">= 1.3"

  backend "s3" {
    bucket                      = "forest-test-spaces"
    key                         = "calibnet-terraform.tfstate"
    region                      = "us-west-1"
    endpoint                    = "nyc3.digitaloceanspaces.com/"
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
  # ssh_keys = 

  image              = var.image
  size               = var.size
  observability_name = var.observability_name
  protocol           = var.protocol
  source_addresses   = var.source_addresses
  attach_volume      = false
}
