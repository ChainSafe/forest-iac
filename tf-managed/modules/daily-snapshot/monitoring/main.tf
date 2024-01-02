# Creation of a new New Relic alert policy for infrastructure or Contianer downtime
resource "newrelic_alert_policy" "alert" {
  name = format("%s alert policy", var.service_name)
}

# NRQL alert conditions for events such as host down, high disk/memory use,
# and container down, each with defined criteria and thresholds.
resource "newrelic_nrql_alert_condition" "disk_space" {
  policy_id                    = newrelic_alert_policy.alert.id
  type                         = "static"
  name                         = "High Disk Utilization"
  description                  = "Alert when disk space usage is high on an the service host"
  enabled                      = true
  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT latest(diskUsedPercent) FROM StorageSample where entityName = '${var.service_name}'"
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
