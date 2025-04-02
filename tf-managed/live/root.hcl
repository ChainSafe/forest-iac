# This is the root terragrunt file. It is used to define the remote state
# and the common inputs for all the services.

locals {
  # Parse the file path we're in to read the env name: e.g., env
  # will be "dev" in the dev folder, "stage" in the stage folder,
  # etc.
  parsed = regex(".*/environments/(?P<env>.*?)/.*", get_terragrunt_dir())
  env    = local.parsed.env
}

# Remote state, separate for each environment and service.
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    // Provide some basic separation between development and production environments.
    // Ideally, we'd use separate accounts for each environment, but that's not
    // feasible at the moment.
    bucket = (local.env == "prod"
      ? "forest-iac-bucket-prod"
      : "forest-iac-bucket-dev"
    )
    key                                = "${path_relative_to_include()}/terraform.tfstate"
    region                             = "eu-west-1"
    endpoint                           = "https://fra1.digitaloceanspaces.com"
    skip_bucket_versioning             = true
    skip_bucket_ssencryption           = true
    skip_bucket_root_access            = true
    skip_bucket_public_access_blocking = true
    skip_bucket_enforced_tls           = true
    skip_credentials_validation        = true
    skip_metadata_api_check            = true
    skip_requesting_account_id         = true
    skip_s3_checksum                   = true
    skip_region_validation             = true
  }
}

# Common inputs for all the services.
inputs = {
  # The common resources dir contains common code that we want to share across all services.
  # This is a legacy from the previous version of the infrastructure, and will be removed
  # in the future.
  common_resources_dir = format("%s/../scripts", get_parent_terragrunt_dir())
  slack_channel        = (local.env == "prod" ? "#forest-notifications" : "#forest-dump")
  environment          = local.env
}
