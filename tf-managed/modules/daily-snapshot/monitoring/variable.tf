variable "service_name" {
  description = "The name of the service"
  type        = string
}

variable "enable_slack_notifications" {
  description = "Enable Slack notifications"
  type        = bool
  default     = false
}
