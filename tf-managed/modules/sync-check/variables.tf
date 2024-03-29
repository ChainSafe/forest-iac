variable "digitalocean_token" {
  description = "Token for authentication."
  type        = string
  sensitive   = true
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
  sensitive   = true
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

variable "new_relic_region" {
  description = "The New Relic Platform Region"
  type        = string
  default     = "EU"
}

variable "new_relic_api_key" {
  description = "New Relic API KEY"
  default     = ""
  type        = string
  sensitive   = true
}

variable "new_relic_account_id" {
  description = "The New Relic Account ID"
  default     = ""
  type        = string
  sensitive   = true
}

variable "common_resources_dir" {
  type = string
}

variable "environment" {
  description = "The environment name"
  type        = string
}
