# This Terraform script configures an environment to use New Relic for infrastructure monitoring
# and alerting, including setting up alert policies and a notification channel for Slack.

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
  api_key    = var.NEW_RELIC_API_KEY
  region     = "EU" # Valid regions are US and EU
}

# This block of code uses Terraform's data source to fetch details of an existing New Relic 
# alert policy named "Golden Signals". The "Golden Signals" are a set of monitoring parameters
# that originate from the Google SRE (Site Reliability Engineering) Handbook. They provide
# a high level overview of a system's health and are typically included in most monitoring setups.
#
# In the context of New Relic, the "Golden Signals" alert policy is created by default 
#  when a new New Relic account is created. This policy includes a set of predefined alert conditions based
# on the Google's Golden Signals concept.
#
# By fetching this policy using the data source, we can integrate these conditions with other
# resources managed in this script, such as linking it with a notification channel or adding it 
# to a workflow.

data "newrelic_alert_policy" "golden_signals" {
  name = "Golden Signals"
}

# Creation of a new New Relic alert policy for infrastructure or Contianer downtime 
resource "newrelic_alert_policy" "alert" {
  name = "Infrastruture Downtime Alert"
}

# Different NRQL alert conditions for various types of events including host down,
# high disk space, high RAM utilization, high memory utilization, and container issues
# Each condition has specific criteria and triggers for warning and critical alerts
# The NRQL (New Relic Query Language) query is used to determine when the alert conditions are met
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

}

resource "newrelic_nrql_alert_condition" "disk_space" {
  policy_id                    = newrelic_alert_policy.alert.id
  type                         = "static"
  name                         = "disk_space"
  description                  = "Alert when disk space usage is high on any host"
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
  description                  = "Alert when any container on any host is down or restarting for more than 5 minutes"
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

# Setting up a Slack channel as the notification channel for alerts
resource "newrelic_notification_channel" "slack-channel" {
  name           = "slack"
  type           = "SLACK"
  destination_id = var.slack_destination_id
  product        = "IINT"

  property {
    key   = "channelId"
    value = var.slack_channel_id
  }
  property {
    key   = "customDetailsSlack"
    value = "The '{{  annotations.description }}' has been activated. The condition has exceeded the defined threshold. Kindly examine this issue on the New Relic dashboard for more extensive data and potential mitigation steps."

  }
}

# Creation of a New Relic workflow that includes issues filtered by the policy IDs
# and sends notifications to the configured Slack channel
resource "newrelic_workflow" "slack_workflow" {
  name                  = "Slack Workflow"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "Filter-name"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.alert.id, data.newrelic_alert_policy.golden_signals.id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.slack-channel.id
  }
}

