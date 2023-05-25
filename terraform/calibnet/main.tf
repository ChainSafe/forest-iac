terraform {
  required_version = ">= 1.2"

  backend "s3" {
    bucket                      = "forest-iac"
    key                         = "forest-calibnet/terraform.tfstate"
    region                      = "us-west-1"
    endpoint                    = "fra1.digitaloceanspaces.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

module "calibnet" {
  source = "../modules/forest_node"

  digitalocean_token    = var.digitalocean_token
  name                  = var.name
  region                = var.region
  image                 = var.image
  size                  = var.size
  observability_name    = var.observability_name
  protocol              = "tcp"
  source_addresses      = var.source_addresses
  attach_volume         = false
  destination_addresses = var.destination_addresses
  enviroment            = var.enviroment
  project               = var.project
}
