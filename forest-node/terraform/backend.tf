terraform {
  backend "s3" {
    bucket                      = ""
    key                         = "terraform.tfstate"
    region                      = "us-west-1"
    endpoint                    = ""
    skip_credentials_validation = "true"
    skip_metadata_api_check     = "true"
  }
}
