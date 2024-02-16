variable "chain" {
  description = "The chain to start forest with. This will also be included in the droplet name"
  type        = string
}

variable "droplet_size" {
  type = string
}

variable "digitalocean_token" {
  type      = string
  sensitive = true
}

variable "environment" {
  type = string
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
