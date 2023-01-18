# terraform {
#   backend "s3" {
#     bucket = "forest-terraform-state"
#     region = "lon1"
#     endpoint = "lon1.digitaloceanspaces.com"
#     access_key = "digitalocean_space_access_key.forest.access_key"
#     secret_key = "digitalocean_secret.forest.value"
#     key = "path/to/state-file"
#   }
# }