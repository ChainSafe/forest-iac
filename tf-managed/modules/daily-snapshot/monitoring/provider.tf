terraform {
  required_version = "~> 1.3"
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 3.0"
    }
  }
}

# # Configure the New Relic provider
# provider "newrelic" {
#   account_id = var.nr_account_id
#   api_key    = var.nr_api_key
#   region     = var.nr_region
# }
