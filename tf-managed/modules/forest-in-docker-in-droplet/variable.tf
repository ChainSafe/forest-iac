variable "chain" {
  description = "The chain to start forest with. This will also be included in the droplet name"
  type        = string
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
