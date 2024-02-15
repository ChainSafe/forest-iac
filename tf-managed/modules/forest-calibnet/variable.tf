variable "chain" {
  description = "The chain tag to apply to resources."
  type        = string
  default     = "calibnet"
}

variable "droplet_size" {
  type    = string
  default = "s-4vcpu-16gb-amd"
}

variable "digitalocean_token" {
  description = "Token for authentication."
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "new_relic_api_key" {
  default   = null
  sensitive = true
  type      = string
}

variable "new_relic_account_id" {
  default   = null
  sensitive = true
  type      = string
}
