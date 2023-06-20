terraform {
  backend "s3" {
    # Note: This is the bucket for the internal terraform state. This bucket is
    # completely independent from the bucket that contains snapshots.
    bucket = "forest-iac"
    # This key uniquely identifies the service. To create a new service (instead
    # of modifying this one), use a new key. Unfortunately, variables may not be
    # used here.
    key = "daily_snapshot.tfstate"

    # This value is completely unused by DO but _must_ be a known AWS region.
    region = "us-west-1"
    # The S3 region is determined by the endpoint. fra1 = Frankfurt.
    # This region does not have to be shared by the droplet.
    endpoint = "https://fra1.digitaloceanspaces.com"

    # Credentially can be validated through the Security Token Service (STS).
    # Unfortunately, DigitalOcean does not support STS so we have to skip the
    # validation.
    skip_credentials_validation = "true"
  }
}

module "daily_snapshot" {
  # Import the daily_snapshot module
  source = "./modules/daily_snapshot"

  # Configure service:
  name              = "forest-snapshot"       # droplet name
  size              = "so-2vcpu-16gb"         # droplet size
  slack_channel     = "#forest-notifications" # slack channel for notifications
  snapshot_bucket   = "forest-snapshots"
  snapshot_endpoint = "fra1.digitaloceanspaces.com"
  forest_tag        = "latest"

  # Variable passthrough:
  slack_token           = var.slack_token
  AWS_ACCESS_KEY_ID     = var.AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY = var.AWS_SECRET_ACCESS_KEY
  digitalocean_token    = var.do_token
  NR_LICENSE_KEY        = var.NR_LICENSE_KEY 
}

# This ip address may be used in the future by monitoring software
output "ip" {
  value = [module.daily_snapshot.ip]
}
