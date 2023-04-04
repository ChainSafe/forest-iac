variable "image" {
  description = "The ID of the AMI to use for the Droplet"
  type        = string
}

variable "name" {
  description = "The name of Forest Droplet"
  type        = string
}

variable "observability_name" {
  description = "The name of the observability Droplet"
  type        = string
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
}

variable "size" {
  description = "The size of the EC2 instance to launch"
  type        = string
}

variable "backups" {
  description = "A boolean flag indicating whether to enable backups"
  type        = string
}

variable "protocol" {
  description = "The protocol to use for the connection."
  type        = string
}

variable "source_addresses" {
  description = "List of source addresses."
  type        = list(string)
}

variable "digitalocean_token" {
  description = "Token for authentication."
  type        = string
}

variable "volume_size" {
  description = "The size of the volume to create, in gigabytes."
  type        = number
}

variable "initial_filesystem_type" {
  description = "The type of filesystem to create on the new volume."
  type        = string
}

variable "ssh_key" {
  description = "The fingerprint of the new key"
  type        = string
}

variable "destination_addresses" {
  description = "address for the firewall reference"
  type        = list(string)
}

variable "enviroment" {
  description = "The environment tag to apply to resources"
  type        = string
}

variable "volume_name" {
  description = "The name assigned to the volume in the cloud"
  type        = string
}
