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

  do_token              = var.do_token
  name                  = var.name
  region                = var.region
  image                 = var.image
  size                  = var.size
  source_addresses      = var.source_addresses
  attach_volume         = false
  destination_addresses = var.destination_addresses
  chain                 = var.chain
  project               = var.project
  fw_name               = var.fw_name
  NR_LICENSE_KEY        = var.NR_LICENSE_KEY
  NEW_RELIC_API_KEY     = var.NEW_RELIC_API_KEY
  NEW_RELIC_ACCOUNT_ID  = var.NEW_RELIC_ACCOUNT_ID
}
