terraform {
  required_version = "~> 1.3"

  backend "s3" {
    # Note: This is the bucket for the internal terraform state. This bucket is
    # completely independent from the bucket that contains snapshots.
    bucket = "forest-iac"
    # This key uniquely identifies the service. To create a new service (instead
    # of modifying this one), use a new key. Unfortunately, variables may not be
    # used here.
    key = "sync_check.tfstate"

    # This value is completely unused by DO but _must_ be a known AWS region.
    region = "us-west-1"
    # The S3 region is determined by the endpoint. fra1 = Frankfurt.
    # This region does not have to be shared by the droplet.
    endpoints = {
      s3 = "fra1.digitaloceanspaces.com"
    }

    # Credentially can be validated through the Security Token Service (STS).
    # Unfortunately, DigitalOcean does not support STS so we have to skip the
    # validation.
    skip_credentials_validation = "true"
    skip_requesting_account_id  = "true"
  }
}

module "sync_check" {
  # Import the sync_check module
  source = "../modules/sync_check"

  # Configure service:
  name          = "forest-sync-check"     # droplet name
  size          = "s-4vcpu-16gb-amd"      # droplet size
  slack_channel = "#forest-notifications" # slack channel for notifications

  # Variable passthrough:
  slack_token          = var.slack_token
  digitalocean_token   = var.do_token
  NEW_RELIC_API_KEY    = var.NEW_RELIC_API_KEY
  NEW_RELIC_ACCOUNT_ID = var.NEW_RELIC_ACCOUNT_ID
}

# This ip address may be used in the future by monitoring software
output "ip" {
  value = [module.sync_check.ip]
}
