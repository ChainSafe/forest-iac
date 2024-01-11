resource "newrelic_alert_policy" "alert" {
  name = format("%s alert policy", var.service_name)
}

locals {
  enable_email = var.alert_email != ""
}

# resource "newrelic_nrql_alert_condition" "disk_space" {
#   policy_id                    = newrelic_alert_policy.alert.id
#   type                         = "static"
#   name                         = "High Disk Utilization"
#   description                  = "Alert when disk space usage is high on an the service host"
#   enabled                      = true
#
#   nrql {
#     query = "SELECT latest(diskUsedPercent) FROM StorageSample where entityName = '${var.service_name}'"
#   }
#
#   critical {
#     operator              = "above"
#     # threshold             = 85.0
#     threshold             = 20.0
#     threshold_duration    = 300
#     threshold_occurrences = "ALL"
#   }
#
#   warning {
#     operator              = "above"
#     # threshold             = 70.0
#     threshold             = 10.0
#     threshold_duration    = 300
#     threshold_occurrences = "ALL"
#   }
# }

resource "newrelic_notification_destination" "email" {
  count = local.enable_email ? 1 : 0
  name  = format("%s email", var.service_name)
  type  = "EMAIL"

  property {
    key   = "email"
    value = var.alert_email
  }
}

resource "newrelic_notification_channel" "email-channel" {
  count          = local.enable_email ? 1 : 0
  name           = format("%s email", var.service_name)
  type           = "EMAIL"
  product        = "IINT"
  destination_id = newrelic_notification_destination.email[0].id

  property {
    key   = "subject"
    value = format("%s alert", var.service_name)
  }
}

resource "newrelic_notification_channel" "slack-channel" {
  count          = var.slack_enable ? 1 : 0
  name           = format("%s slack", var.service_name)
  type           = "SLACK"
  destination_id = var.slack_destination_id
  product        = "IINT"

  property {
    key   = "channelId"
    value = var.slack_channel_id
  }

  property {
    key   = "customDetailsSlack"
    value = "issue id - {{issueId}}"
  }
}


resource "newrelic_workflow" "alerting-workflow-mails" {
  count                 = local.enable_email ? 1 : 0
  name                  = format("%s mail alerting workflow", var.service_name)
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = format("%s alerting workflow filter", var.service_name)
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.alert.id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.email-channel[0].id
  }
}

# Limitation of NR provider - only one workflow can be created per channel. Might be resolved in the future.
# https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/workflow#nested-destination-blocks
resource "newrelic_workflow" "alerting-workflow-slack" {
  count                 = var.slack_enable ? 1 : 0
  name                  = format("%s slack alerting workflow", var.service_name)
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = format("%s alerting workflow filter", var.service_name)
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.alert.id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.slack-channel[0].id
  }
}

# At least 1 snapshot is generated in 5 hours interval
resource "newrelic_nrql_alert_condition" "snapshot_frequency_condition" {
  for_each    = toset(["mainnet", "calibnet"])
  policy_id   = newrelic_alert_policy.alert.id
  type        = "static"
  name        = format("Low snapshot generation frequency - %s", each.key)
  description = "Alert when snapshots are not generated within requried time interval"
  enabled     = true

  # evaluation_delay = 7200 # 2 hours, it may take some time to generate a snapshot
  # aggregation_window = 14400 # 4 hours, it may take some time to generate a snapshot
  aggregation_window = 360 # 4 hours, it may take some time to generate a snapshot


  nrql {
    query = format("FROM Metric SELECT count(`${var.service_name}.${each.key}.snapshot_generation_ok`)")
  }

  warning {
    operator  = "below"
    threshold = 1
    # threshold_duration    = 14400
    threshold_duration    = 360
    threshold_occurrences = "ALL"
  }

  critical {
    operator  = "below"
    threshold = 1
    # threshold_duration    = 28800
    threshold_duration    = 720
    threshold_occurrences = "ALL"
  }
}

# At least 1 successful snapshot out of 3 attempts

#resource "newrelic_nrql_alert_condition" "disk_space" {
#  policy_id                    = newrelic_alert_policy.alert.id
#  type                         = "static"
#  name                         = "High Disk Utilization"
#  description                  = "Alert when disk space usage is high on an the service host"
#  enabled                      = true
#
#  nrql {
#    query = "SELECT latest(diskUsedPercent) FROM StorageSample where entityName = '${var.service_name}'"
#  }
#
#  critical {
#    operator              = "above"
#    # threshold             = 85.0
#    threshold             = 20.0
#    threshold_duration    = 300
#    threshold_occurrences = "ALL"
#  }
#
#  warning {
#    operator              = "above"
#    # threshold             = 70.0
#    threshold             = 10.0
#    threshold_duration    = 300
#    threshold_occurrences = "ALL"
#  }
#}
