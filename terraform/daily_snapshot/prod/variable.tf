variable "do_token" {
  description = "Token for authentication."
  type        = string
  sensitive   = true
}

variable "R2_ACCESS_KEY" {
  description = "S3 access key id"
  type        = string
  sensitive   = true
}

variable "R2_SECRET_KEY" {
  description = "S3 private access key"
  type        = string
  sensitive   = true
}

variable "slack_token" {
  description = "slack access token"
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
