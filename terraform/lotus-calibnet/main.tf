terraform {
  required_version = ">= 1.2"

  backend "s3" {
    bucket                      = "forest-iac"
    key                         = "lotus-calibnet/terraform.tfstate"
    region                      = "us-west-1"
    endpoint                    = "fra1.digitaloceanspaces.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

module "lotus-calibnet" {
  source = "../modules/forest_node"

  do_token              = var.do_token
  name                  = "lotus"
  region                = "fra1"
  image                 = "docker-20-04"
  size                  = "s-4vcpu-8gb"
  source_addresses      = ["0.0.0.0/0", "::/0"]
  attach_volume         = false
  destination_addresses = ["0.0.0.0/0", "::/0"]
  chain                 = "calibrationnet"
  project               = "Forest-DEV"
  fw_name               = "lotus-calibnet-fw"
  script                = "lotus.sh"
  NR_LICENSE_KEY        = var.NR_LICENSE_KEY
  NEW_RELIC_API_KEY     = var.NEW_RELIC_API_KEY
  NEW_RELIC_ACCOUNT_ID  = var.NEW_RELIC_ACCOUNT_ID
}
