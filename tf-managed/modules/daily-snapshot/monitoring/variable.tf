variable "service_name" {
  description = "The name of the service"
  type        = string
}

variable "new_relic_account_id" {
  description = "The New Relic Account ID"
  default     = 0
  type        = number
  sensitive   = true
}

variable "alert_email" {
  description = "Email address to send alerts to"
  type        = string
  default     = ""
}

variable "slack_enable" {
  description = "Enable Slack notifications"
  type        = bool
  default     = false
}

variable "slack_destination_id" {
  description = "Slack destination id"
  type        = string
}

variable "slack_channel_id" {
  description = "Slack channel id"
  type        = string
}
