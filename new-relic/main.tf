

terraform {
  required_version = "~> 1.0"
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
    } 
  }
  backend "s3" {
    bucket                      = "forest-iac"
    key                         = "new_relic/terraform.tfstate"
    region                      = "us-west-1"
    endpoint                    = "fra1.digitaloceanspaces.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

# Configure the New Relic provider
provider "newrelic" {
  account_id = var.NEW_RELIC_ACCOUNT_ID
  api_key =  var.NEW_RELIC_API_KEY   # usually prefixed with 'NRAK'
  region = "EU"                    # Valid regions are US and EU
}

resource "newrelic_alert_policy" "my_alert_policy_name" {
    name = "first alert"
}

data "newrelic_application" "app_name" {
    name = 
  
}