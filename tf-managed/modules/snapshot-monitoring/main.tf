resource "newrelic_synthetics_script_monitor" "snapshot-age-monitor" {
  status = "ENABLED"
  name   = format("%s-snapshot-age-monitor", var.environment)
  type   = "SCRIPT_API"

  # https://docs.newrelic.com/docs/synthetics/synthetic-monitoring/administration/synthetic-public-minion-ips/#public-minion-locations-and-location-labels-location
  # TODO - parameterize this
  locations_public = ["AP_SOUTHEAST_1", "US_WEST_1", "EU_CENTRAL_1"]
  period           = "EVERY_HOUR"
  script           = file("snapshot-age-monitor.js")

  script_language      = "JAVASCRIPT"
  runtime_type         = "NODE_API"
  runtime_type_version = "16.10"

  tag {
    key    = "service"
    values = ["forest-snapshot"]
  }
}
