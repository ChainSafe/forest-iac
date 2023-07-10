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

variable "NR_LICENSE_KEY" {
  description = "New Relic Access Token"
  type        = string
}

