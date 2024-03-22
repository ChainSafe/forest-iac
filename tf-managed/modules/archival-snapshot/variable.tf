variable "name" {
  description = "The name of the server"
  type        = string
}

variable "slack_channel" {
  description = "Slack channel name for notifications"
  type        = string
}

variable "slack_token" {
  description = "Slack access token"
  type        = string
  sensitive   = true
}
