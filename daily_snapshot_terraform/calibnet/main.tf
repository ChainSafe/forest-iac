terraform {
  backend "s3" {
    bucket = "forest-iac"
    key    = "daily_snapshot_calibnet.tfstate"
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
  source = "../modules/daily_snapshot"

  name  = "test-forest-snapshot-calibnet"
  chain = "calibnet"
  size  = "s-4vcpu-8gb"

  slack_channel = "#forest-notifications"

  slack_token                 = var.slack_token
  AWS_ACCESS_KEY_ID           = var.AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY       = var.AWS_SECRET_ACCESS_KEY
  new_key_ssh_key_fingerprint = var.ssh_fingerprint
  digitalocean_token          = var.do_token
}

# This ip address may be used in the future by monitoring software
output "ip" {
  value = [module.daily_snapshot.ip]
}
