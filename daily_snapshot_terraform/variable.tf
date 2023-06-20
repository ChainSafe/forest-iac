variable "do_token" {
  description = "Token for authentication."
  type        = string
}

variable "AWS_ACCESS_KEY_ID" {
  description = "S3 access key id"
  type        = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "S3 private access key"
  type        = string
}

variable "slack_token" {
  description = "slack access token"
  type        = string
}

variable "NR_LICENSE_KEY" {
  description = "New Relic Access Token"
  type        = string
}

