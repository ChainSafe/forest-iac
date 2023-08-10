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

variable "snapshot_bucket" {
  description = "S3 bucket containing the snapshots"
  type        = string
  default     = "forest-snapshots"
}

variable "snapshot_endpoint" {
  description = "S3 endpoint for the snapshots"
  type        = string
  default     = "https://fra1.digitaloceanspaces.com/"
}

variable "forest_tag" {
  description = "Image tag for the Forest container"
  type        = string
  default     = "latest"
}

variable "image" {
  description = "The ID of the AMI to use for the Droplet"
  type        = string
  default     = "fedora-36-x64"
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

variable "source_addresses" {
  description = "List of source addresses."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "destination_addresses" {
  description = "List of destination addresses."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "NR_LICENSE_KEY" {
  description = "New Relic Access Token"
  default     = ""
  type        = string
}
