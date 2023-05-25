variable "image" {
  description = "The ID of the AMI to use for the Droplet"
  type        = string
}

variable "name" {
  description = "The name of Forest Droplet"
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

variable "source_addresses" {
  description = "List of source addresses."
  type        = list(string)
}

variable "digitalocean_token" {
  description = "Token for authentication."
  type        = string
}

variable "destination_addresses" {
  description = "address for the firewall reference"
  type        = list(string)
}

variable "enviroment" {
  description = "The environment tag to apply to resources."
  type        = string
}

variable "project" {
  description = "The name assigned to the project in the cloud"
  type        = string
}
