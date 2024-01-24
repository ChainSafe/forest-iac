locals {
  service_name = format("%s-snapshot-age-monitor", var.environment)
}

resource "newrelic_alert_policy" "alert" {
  name = format("%s alert policy", local.service_name)
}

resource "newrelic_synthetics_script_monitor" "snapshot-age-monitor" {
  status = "ENABLED"
  name   = format("%s-snapshot-age-monitor", var.environment)
  type   = "SCRIPT_API"

  # https://docs.newrelic.com/docs/synthetics/synthetic-monitoring/administration/synthetic-public-minion-ips/#public-minion-locations-and-location-labels-location
  locations_public = ["AP_SOUTHEAST_1", "US_WEST_1", "EU_CENTRAL_1"]
  period           = "EVERY_HOUR"
  script           = file("snapshot-age-monitor.js")

  script_language      = "JAVASCRIPT"
  runtime_type         = "NODE_API"
  runtime_type_version = "16.10"

  tag {
    key    = "service"
    values = ["forest-snapshot", var.environment]
  }
}

resource "newrelic_notification_channel" "slack-channel" {
  count          = var.slack_enable ? 1 : 0
  name           = format("%s slack", local.service_name)
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

resource "newrelic_notification_channel" "pagerduty-channel" {
  count          = var.pagerduty_enable ? 1 : 0
  name           = format("%s pagerduty", local.service_name)
  type           = "PAGERDUTY_SERVICE_INTEGRATION"
  destination_id = var.pagerduty_destination_id
  product        = "IINT"

  property {
    key   = "summary"
    value = "Filecoin Forest snapshot age monitor {{#isCritical}}CRITICAL{{/isCritical}}{{#isWarning}}WARNING{{/isWarning}}"
  }

  property {
    key   = "customDetails"
    value = <<-EOT
            {
            "id":{{json issueId}},
            "IssueURL":{{json issuePageUrl}},
            "NewRelic priority":{{json priority}},
            "Total Incidents":{{json totalIncidents}},
            "Impacted Entities":"{{#each entitiesData.names}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}",
            "Runbook":"{{#each accumulations.runbookUrl}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}",
            "Description":"{{#each annotations.description}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}",
            "isCorrelated":{{json isCorrelated}},
            "Alert Policy Names":"{{#each accumulations.policyName}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}",
            "Alert Condition Names":"{{#each accumulations.conditionName}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}",
            "Workflow Name":{{json workflowName}}
            }
        EOT
  }
}

resource "newrelic_nrql_alert_condition" "failing-snapshot-age" {
  policy_id = newrelic_alert_policy.alert.id
  name      = format("%s failing snapshot age", local.service_name)
  enabled   = true
  # Bound to the monitor query interval which is `EVERY_HOUR`
  aggregation_window = 3600

  nrql {
    query = "SELECT filter(count(*), WHERE result = 'FAILED') AS 'Failures' FROM SyntheticCheck WHERE monitorName = '${local.service_name}'"
  }

  # This means that all locations are failing
  critical {
    operator              = "above_or_equals"
    threshold             = 3
    threshold_duration    = 3600
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "above_or_equals"
    threshold             = 2
    threshold_duration    = 3600
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_workflow" "alerting-workflow-slack" {
  count                 = var.slack_enable ? 1 : 0
  name                  = format("%s slack alerting workflow", local.service_name)
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = format("%s alerting workflow filter", local.service_name)
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

resource "newrelic_workflow" "alerting-workflow-pagerduty" {
  count                 = var.pagerduty_enable ? 1 : 0
  name                  = format("%s pagerduty alerting workflow", local.service_name)
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = format("%s alerting workflow filter", local.service_name)
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.alert.id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.pagerduty-channel[0].id
  }
}
