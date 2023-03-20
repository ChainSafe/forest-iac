variable "digitalocean_token" {
  description = "Token for authentication."
  type        = string
}

variable "new_key_ssh_key_fingerprint" {
  description = "the ssh key fingerprint for digitalocean"
  type        = string
}
