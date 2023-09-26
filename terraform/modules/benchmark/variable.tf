variable "digitalocean_token" {
  description = "Token for authentication."
  type        = string
}

variable "name" {
  description = "The name of Forest Droplet"
  type        = string
}

variable "size" {
  description = "The size of the droplet instance to launch"
  type        = string
}

variable "slack_channel" {
  description = "slack channel name for notifications"
  type        = string
}

variable "slack_token" {
  description = "slack access token"
  type        = string
}

variable "AWS_ACCESS_KEY_ID" {
  description = "S3 access key id"
  type        = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "S3 private access key"
  type        = string
}

variable "benchmark_bucket" {
  description = "S3 bucket containing the benchmark results"
  type        = string
  default     = "forest-benchmarks"
}

variable "benchmark_endpoint" {
  description = "S3 endpoint for the benchmark results"
  type        = string
  default     = "https://fra1.digitaloceanspaces.com/"
}

variable "image" {
  description = "The ID of the AMI to use for the Droplet"
  type        = string
  default     = "docker-20-04"
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
  default     = "fra1"
}

variable "project" {
  description = "DigitalOcean project used as parent for the created droplet"
  type        = string
  default     = "Forest-DEV" # Alternative: "Default"
}

variable "NEW_RELIC_API_KEY" {
  description = "New Relic API KEY"
  default     = ""
  type        = string
}

variable "NEW_RELIC_ACCOUNT_ID" {
  description = "New Relic Account ID"
  default     = ""
  type        = string
}

variable "NEW_RELIC_REGION" {
  description = "The New Relic Platform Region"
  type        = string
  default     = "EU"
}

variable "lotus_latest_tag" {
  description = "The git tag of Lotus client for the benchmark"
  type        = string
  # If you change from default do not forget to update the Go version in the Dockerfile.
  # Go version v1.19.12 or higher is needed for this version. Go version 1.20 is also supported, but 1.21 is NOT.
  default     = "release/v1.23.3"
}
