variable "NEW_RELIC_ACCOUNT_ID" {
  description = "New Relic Account ID"
  default = ""
  type = string
  sensitive = true
}

variable "NEW_RELIC_ACCOUNT_ID" {
  description = "The New Relic Account ID"
  type = string
  sensitive = true
}

variable "NEW_RELIC_API_KEY" {
  description = "New Relic API KEY"
  default = ""
  type = string
  sensitive = true
}

variable "NEW_RELIC_API_KEY" {
  description = "New Relic API KEY"
  type = string
  sensitive = true
}

variable "NEW_RELIC_REGION" {
  description = "The New Relic Platform Region"
  type = string
  default = "EU"
}

variable "NR_LICENSE_KEY" {
  description = "New Relic Access Token"
  default = ""
  type = string
  sensitive = true
}

variable "NR_LICENSE_KEY" {
  description = "New Relic Access Token"
  type = string
  sensitive = true
}

variable "attach_volume" {
  description = "If set to true, it will create and attached volume"
  type = bool
}

variable "chain" {
  description = "The chain tag to apply to resources."
  type = string
}

variable "destination_addresses" {
  description = "address for the firewall reference"
  type = list(string)
}

variable "digitalocean_token" {
  description = "Token for authentication."
  type = string
  sensitive = true
}

variable "do_token" {
  description = "Token for authentication."
  type = string
  sensitive = true
}

variable "environment" {
  description = "The environment name"
  type = string
}

variable "forest_user" {
  description = "The name of Forest Droplet user"
  type = string
}

variable "fw_name" {
  description = "The name assigned to the firewall in the cloud"
  type = string
}

variable "fw_name" {
  description = "The name assigned to the volume in the cloud"
  type = string
}

variable "image" {
  description = "The ID of the AMI to use for the Droplet"
  type = string
}

variable "initial_filesystem_type" {
  description = "The type of filesystem to create on the new volume."
  type = string
  default = "ext4"
}

variable "name" {
  description = "The name of Forest Droplet"
  type = string
}

variable "project" {
  description = "The name assigned to the project in the cloud"
  type = string
}

variable "region" {
  description = "The region where resources will be created"
  type = string
}

variable "rpc_port" {
  description = "RPC Port for nodes"
  type = string
}

variable "script" {
  description = "The Name of the Script Executed at the Initialization of the Droplet"
  type = string
  default = "forest.sh"
}

variable "size" {
  description = "The size of the EC2 instance to launch"
  type = string
}

variable "source_addresses" {
  description = "List of source addresses."
  type = list(string)
}

variable "volume_name" {
  description = "The name assigned to the volume in the cloud"
  type = string
  default = ""
}

variable "volume_size" {
  description = "The size of the volume to create, in gigabytes."
  type = number
  default = 100
}
