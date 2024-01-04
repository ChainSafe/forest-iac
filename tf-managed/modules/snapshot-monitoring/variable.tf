variable "environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "new_relic_region" {
  description = "The New Relic Platform Region"
  type        = string
  default     = "EU"
}

variable "new_relic_api_key" {
  description = "New Relic API KEY"
  default     = ""
  type        = string
  sensitive   = true
}

variable "new_relic_account_id" {
  description = "The New Relic Account ID"
  default     = 0
  type        = number
  sensitive   = true
}
