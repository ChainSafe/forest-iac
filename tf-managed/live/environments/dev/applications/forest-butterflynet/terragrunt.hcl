# Automatically find the root terragrunt.hcl and inherit its
# configuration
include "root" {
  path = find_in_parent_folders()
}

# Load the actual Terraform module
terraform {
  source = format("%s/../modules/forest-droplet", get_parent_terragrunt_dir())
}

inputs = {
  chain        = "butterflynet"
  droplet_size = "s-1vcpu-2gb-amd"
  service_name = "forest-butterflynet"
  forest_tag   = "2024-03-25-44c3331-fat"
}
