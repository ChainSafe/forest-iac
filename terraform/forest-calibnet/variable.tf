variable "image" {
  description = "The ID of the AMI to use for the Droplet"
  type        = string
}

variable "name" {
  description = "The name of Forest Droplet"
  type        = string
}

variable "forest_user" {
  description = "The name of Forest Droplet user"
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

variable "do_token" {
  description = "Token for authentication."
  type        = string
  sensitive   = true
}

variable "destination_addresses" {
  description = "address for the firewall reference"
  type        = list(string)
}

variable "chain" {
  description = "The chain tag to apply to resources."
  type        = string
}

variable "project" {
  description = "The name assigned to the project in the cloud"
  type        = string
}

variable "fw_name" {
  description = "The name assigned to the volume in the cloud"
  type        = string
}

variable "NR_LICENSE_KEY" {
  description = "New Relic Access Token"
  type        = string
  sensitive   = true
}

variable "NEW_RELIC_API_KEY" {
  description = "New Relic API KEY"
  type        = string
  sensitive   = true
}

variable "NEW_RELIC_ACCOUNT_ID" {
  description = "The New Relic Account ID"
  type        = string
  sensitive   = true
}
