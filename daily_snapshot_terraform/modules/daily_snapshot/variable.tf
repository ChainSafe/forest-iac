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

variable "backups" {
  description = "A boolean flag indicating whether to enable backups"
  type        = string
  default     = false
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
