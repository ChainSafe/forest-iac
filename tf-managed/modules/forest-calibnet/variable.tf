
variable "chain" {
  description = "The chain tag to apply to resources."
  type        = string
  default     = "calibnet"
}

variable "destination_addresses" {
  description = "address for the firewall reference"
  type        = list(string)
  default     = ["0.0.0.0/0" /* all */]
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

variable "forest_user" {
  description = "The name of Forest Droplet user"
  type        = string
  default     = "forest_user"
}

variable "image" {
  description = "The ID of the AMI to use for the Droplet"
  type        = string
  default     = "docker-20-04" // https://marketplace.digitalocean.com/apps/docker
}

variable "initial_filesystem_type" {
  description = "The type of filesystem to create on the new volume."
  type        = string
  default     = "ext4"
}

variable "name" {
  description = "The name of Forest Droplet"
  type        = string
}

variable "project" {
  description = "The name assigned to the project in the cloud"
  type        = string
  default     = "Forest-DEV"
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
  default     = "fra1"
}

variable "rpc_port" {
  description = "RPC Port for nodes"
  type        = string
  default     = "1234"
}

variable "size" {
  description = "The size of the EC2 instance to launch"
  type        = string
}

variable "source_addresses" {
  description = "List of source addresses."
  type        = list(string)
  default     = ["0.0.0.0/0" /* all */]
}

variable "volume_name" {
  description = "The name assigned to the volume in the cloud"
  type        = string
  default     = ""
}

variable "volume_size" {
  description = "The size of the volume to create, in gigabytes."
  type        = number
  default     = 100
}
