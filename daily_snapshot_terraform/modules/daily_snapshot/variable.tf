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

variable "new_key_ssh_key_fingerprint" {
  description = "the ssh key fingerprint for digitalocean"
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

variable "chain" {
  description = "Chain name (calibnet or mainnet)"
  type        = string
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
