locals {
  # Parse the file path we're in to read the env name: e.g., env
  # will be "dev" in the dev folder, "stage" in the stage folder,
  # etc.
  parsed = regex(".*/environments/(?P<env>.*?)/.*", get_terragrunt_dir())
  env    = local.parsed.env
}

# Remote state, separate for each environment
remote_state {
  backend = "s3"
  generate = {
    path = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    // if the environment is dev, use the dev bucket, otherwise use the prod bucket
    bucket = (local.env == "prod"
             ? "hubert-bucket-prod"
             : "hubert-bucket-dev"
             )
    key    = "${local.env}-terraform.tfstate"
    region = "eu-west-1"
    endpoint = "https://fra1.digitaloceanspaces.com"
    //endpoints = {
    //  s3 = "https://fra1.digitaloceanspaces.com"
    //}
    skip_bucket_versioning = true
    skip_bucket_ssencryption = true
    skip_bucket_root_access = true
    skip_bucket_public_access_blocking = true
    skip_bucket_enforced_tls = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_region_validation      = true
  }
}

# Common inputs for all the services.
inputs = {
  common_resources_dir = format("%s/../common", get_parent_terragrunt_dir())
  slack_channel        = (local.env == "prod" ? "#forest-notifications" : "#forest-dump")
  env                  = local.env
}
