terraform {
  required_version = "~> 1.0"
  required_providers {
    newrelic = {
      source = "newrelic/newrelic"
    }
  }
  backend "s3" {
    bucket                      = "forest-iac"
    key                         = "new_relic/terraform.tfstate"
    region                      = "us-west-1"
    endpoint                    = "fra1.digitaloceanspaces.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

# Configure the New Relic provider
provider "newrelic" {
  account_id = var.NEW_RELIC_ACCOUNT_ID
  api_key    = var.NEW_RELIC_API_KEY # usually prefixed with 'NRAK'
  region     = "EU"                  # Valid regions are US and EU
}


resource "newrelic_alert_policy" "alert" {
  name = "Infrastruture Downtime Alert"
}

resource "newrelic_nrql_alert_condition" "host_down" {
  policy_id                    = newrelic_alert_policy.alert.id
  type                         = "static"
  name                         = "host_down alert"
  description                  = "Alert when any host is offline"
  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT count(*) FROM SystemSample WHERE agentState = 'offline'"
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "above"
    threshold             = 70.0
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "disk_space" {
  policy_id                    = newrelic_alert_policy.alert.id
  type                         = "static"
  name                         = "disk_space"
  description                  = "Alert when disk space usage is high on any host"
  runbook_url                  = "https://www.example.com"
  enabled                      = true
  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT average(diskUsedPercent) FROM SystemSample FACET entityName"
  }

  critical {
    operator              = "above"
    threshold             = 85.0
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "above"
    threshold             = 70.0
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "high_ram_utilization" {
  policy_id                    = newrelic_alert_policy.alert.id
  type                         = "static"
  name                         = "high_ram_utilization"
  description                  = "Alert when memory usage is high on any host"
  enabled                      = true
  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT average(memoryUsedPercent) FROM SystemSample FACET entityName "
  }

  critical {
    operator              = "above"
    threshold             = 85.0
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "above"
    threshold             = 70.0
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "high_memory_utilization" {
  policy_id                    = newrelic_alert_policy.alert.id
  type                         = "static"
  name                         = "high_ram_utilization"
  description                  = "Alert when memory usage is high on any host"
  enabled                      = true
  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT average(memoryUsedPercent) FROM SystemSample FACET entityName "
  }

  critical {
    operator              = "above"
    threshold             = 85.0
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "above"
    threshold             = 70.0
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "container_issue" {
  policy_id                    = newrelic_alert_policy.alert.id
  type                         = "static"
  name                         = "container_issue"
  description                  = "Alert when any container on any host is down or restarting for more than 10 minutes"
  enabled                      = true
  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT count(*) FROM ContainerSample WHERE (state = 'stopped' OR state = 'restarting') FACET containerName, entityName"
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 300
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}

# Notification channel
# resource "newrelic_notification_channel" "slack_notification_channel" {
#   name           = "Sample Notification Channel"
#   type           = "EMAIL"
#   destination_id = newrelic_notification_destination.sample_notification_destination.id
#   product        = "IINT"

#   property {
#     key   = "subject"
#     value = "Sample Email Subject"
#   }
# }

# resource "newrelic_workflow" "slack_workflow" {
#   name                  = "Sample Workflow"
#   muting_rules_handling = "NOTIFY_ALL_ISSUES"

#   issues_filter {
#     name = "Issue Filter"
#     type = "FILTER"
#     predicate {
#       attribute = "labels.policyIds"
#       operator  = "EXACTLY_MATCHES"
#       values    = [newrelic_alert_policy.alert_policy_name.id]
#     }
#   }

#   destination {
#     channel_id = newrelic_notification_channel.sample_notification_channel.id
#   }
# }