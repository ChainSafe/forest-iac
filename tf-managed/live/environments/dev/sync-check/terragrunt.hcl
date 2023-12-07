# Automatically find the root terragrunt.hcl and inherit its
# configuration
include {
  path = find_in_parent_folders()
}

# Load the actual Terraform module
terraform {
  source = format("%s/../modules/sync-check", get_parent_terragrunt_dir())
}

inputs = {
  name          = "hubert-sync-check-dev" # TODO get environment from terragrunt
  size          = "s-4vcpu-16gb-amd"
}
