terraform {
  backend "s3" {
    bucket = "forest-iac"
    key = "daily_snapshot_calibnet.tfstate"
    # This value is completely unused by DO but _must_ be a known AWS region.
    region = "us-west-1" 
    # The S3 region is determined by the endpoint. fra1 = Frankfurt.
    # This region does not have to be shared by the droplet.
    endpoint = "https://fra1.digitaloceanspaces.com"

    # For reasons, Terraform cannot validate DO credentials.
    skip_credentials_validation = "true"
  }
}

module "daily_snapshot" {
	source = "../modules/daily_snapshot"

  name = "test-forest-snapshot-calibnet"
  size = "s-4vcpu-8gb"

  new_key_ssh_key_fingerprint = var.new_key_ssh_key_fingerprint
  digitalocean_token = var.digitalocean_token
}

output "ip" {
  value = [module.daily_snapshot.ip]
}

output "files" {
  value = [module.daily_snapshot.files]
}
