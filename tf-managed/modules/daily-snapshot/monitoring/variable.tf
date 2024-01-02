# variable "new_relic_account_id" {
#   type        = string
#   description = "The New Relic Account ID"
#   sensitive   = true
# }
#
# variable "new_relic_api_key" {
#   description = "The New Relic API KEY"
#   type        = string
#   sensitive   = true
# }
#
# variable "new_relic_region" {
#   description = "The New Relic Region"
#   type        = string
# }

variable "service_name" {
  description = "The name of the service"
  type        = string
}

variable "enable_slack_notifications" {
  description = "Enable Slack notifications"
  type        = bool
  default     = false
}

# variable "slack_destination_id" {
#   description = "The unique identifier for the Slack workspace where notifications will be sent."
#   # TODO: parametrize
#   default     = "f902e020-5993-4425-9ae3-133084fc870d"
#   type        = string
# }
#
# variable "slack_channel_id" {
#   description = "The unique identifier for the Slack channel(forest-notifications), where notifications will be posted."
#   type        = string
#   # TODO: parametrize
#   default     = "C036TCEF0CU"
# }
