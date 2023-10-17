variable "do_token" {
  description = "Token for authentication."
  type        = string
}

variable "R2_ACCESS_KEY" {
  description = "S3 access key id"
  type        = string
}

variable "R2_SECRET_KEY" {
  description = "S3 private access key"
  type        = string
}

variable "slack_token" {
  description = "slack access token"
  type        = string
}
