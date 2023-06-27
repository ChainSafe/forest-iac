variable "NEW_RELIC_ACCOUNT_ID" {
  type        = string
  description = "The New Relic Account ID"
}

variable "NEW_RELIC_API_KEY" {
  description = "The New Relic API KEY"
  type        = string
}

variable "slack_destination_id" {
  description = "The unique identifier for the Slack workspace where notifications will be sent."
  default     = "f902e020-5993-4425-9ae3-133084fc870d"
  type        = string
}

variable "slack_channel_id" {
  description = "The unique identifier for the Slack channel where notifications will be posted."
  type        = string
  default     = "C05BHMZ7GTT"
}

