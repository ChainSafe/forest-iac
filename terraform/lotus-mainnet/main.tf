terraform {
  required_version = ">= 1.2"

  backend "s3" {
    bucket                      = "forest-iac"
    key                         = "lotus-mainnet/terraform.tfstate"
    region                      = "us-west-1"
    endpoint                    = "fra1.digitaloceanspaces.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

module "lotus-mainnet" {
  source = "../modules/filecoin_node"

  do_token                = var.do_token
  name                    = "lotus-mainnet"
  region                  = "fra1"
  image                   = "s-8vcpu-16gb"
  size                    = "s-4vcpu-8gb"
  source_addresses        = ["0.0.0.0/0", "::/0"]
  attach_volume           = true
  destination_addresses   = ["0.0.0.0/0", "::/0"]
  volume_name             = "lotus-mainnet-volume"
  initial_filesystem_type = "ext4"
  volume_size             = "1000"
  chain                   = "mainnet"
  project                 = "Forest-DEV"
  fw_name                 = "lotus-mainnet-fw"
  script                  = "lotus.sh"
  forest_user             = "forest"
  NR_LICENSE_KEY          = var.NR_LICENSE_KEY
  NEW_RELIC_API_KEY       = var.NEW_RELIC_API_KEY
  NEW_RELIC_ACCOUNT_ID    = var.NEW_RELIC_ACCOUNT_ID
}
