terraform {
  backend "s3" {
    bucket = var.spaces_name
    key = var.bucket_state
    region = var.backend_region
    endpoint =var.spaces_endpoint
    skip_credentials_validation = var.skip_credentials_validation 
    skip_metadata_api_check = var.skip_metadata_api_check
  }
}