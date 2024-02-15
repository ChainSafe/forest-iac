# Automatically find the root terragrunt.hcl and inherit its
# configuration
include "root" {
  path = find_in_parent_folders()
}

# Load the actual Terraform module
terraform {
  source = format("%s/../modules/forest-in-docker-in-droplet", get_parent_terragrunt_dir())
}

inputs = {
  chain = "calibnet"
}
