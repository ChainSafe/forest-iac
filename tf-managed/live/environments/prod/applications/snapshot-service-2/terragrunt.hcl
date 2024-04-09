# Automatically find the root terragrunt.hcl and inherit its
# configuration
include "root" {
  path = find_in_parent_folders()
}

# Load the actual Terraform module
terraform {
  source = format("%s/../modules/daily-snapshot", get_parent_terragrunt_dir())
}

inputs = {
  name            = "forest-snapshot-2"
  size            = "s-4vcpu-16gb-amd"
  r2_endpoint     = "https://2238a825c5aca59233eab1f221f7aefb.r2.cloudflarestorage.com/"
  forest_tag      = "v0.17.2-fat"
  snapshot_bucket = "forest-archive"
  region          = "sfo3"

  monitoring = {
    enable = true,
  }
}
