terraform {
  required_version = "~> 1.3"

  backend "s3" {
    bucket                      = "forest-iac"
    key                         = "forest_mainnet/terraform.tfstate"
    region                      = "us-west-1"
    endpoint                    = "fra1.digitaloceanspaces.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

module "mainnet" {
  source = "../modules/forest_node"

  do_token                = var.do_token
  name                    = var.name
  region                  = var.region
  image                   = var.image
  size                    = var.size
  source_addresses        = var.source_addresses
  initial_filesystem_type = var.initial_filesystem_type
  volume_size             = var.volume_size
  attach_volume           = true
  destination_addresses   = var.destination_addresses
  chain                   = var.chain
  volume_name             = var.volume_name
  project                 = var.project
  fw_name                 = var.fw_name
  NEW_RELIC_API_KEY       = var.NEW_RELIC_API_KEY
  NR_LICENSE_KEY          = var.NR_LICENSE_KEY
}
