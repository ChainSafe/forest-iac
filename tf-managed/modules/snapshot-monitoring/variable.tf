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

variable "slack_enable" {
  description = "Enable Slack notifications"
  type        = bool
  default     = false
}

# This needs to be created manually. Afterwards, it can be found in
# NR / Alerts & AI / Destinations.
variable "slack_destination_id" {
  description = "Slack destination id"
  type        = string
  default     = ""
  sensitive   = true
}

# Channel ID - due to the limitations of NR it's not a human readable name
# but an ID. This can be found at the bottom of the channel settings window.
variable "slack_channel_id" {
  description = "Slack channel id"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_enable" {
  description = "Enable PagerDuty notifications"
  type        = bool
  default     = false
}

# This needs to be created manually. Afterwards, it can be found in
# NR / Alerts & AI / Destinations. Otherwise, we'd need special permissions
# to create it via the API.
variable "pagerduty_destination_id" {
  description = "PagerDuty destination id"
  type        = string
  default     = ""
  sensitive   = true
}
