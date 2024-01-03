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

variable "R2_ACCESS_KEY" {
  description = "S3 access key id"
  type        = string
  sensitive   = true
}

variable "R2_SECRET_KEY" {
  description = "S3 private access key"
  type        = string
  sensitive   = true
}

variable "snapshot_bucket" {
  description = "S3 bucket containing the snapshots"
  type        = string
  default     = "forest-snapshots"
}

variable "r2_endpoint" {
  description = "R2 endpoint for the snapshots"
  type        = string
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
  default     = 0
  type        = number
  sensitive   = true
}

variable "common_resources_dir" {
  type        = string
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "monitoring" {
  description = "Service monitoring"
  type = object({
    enable = optional(bool, false)
    alert_email = optional(string, "")
  })

  default = {
      enable = false,
      alert_email = ""
  }
}
