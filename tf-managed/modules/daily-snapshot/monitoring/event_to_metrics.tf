# This file constains NR event rules used to generate metrics from logs, given that
# the service is not generating metrics by itself.
resource "newrelic_events_to_metrics_rule" "generate_snapshot_attempt_metrics" {
  account_id = var.new_relic_account_id
  for_each   = toset(["mainnet", "calibnet"])

  name        = format("%s %s snapshot generation attempts", var.service_name, each.key)
  description = "Snapshot generation attempts"
  nrql        = "From Log select uniqueCount(message) as '${var.service_name}.${each.key}.snapshot_generation_run' WHERE `hostname` = '${var.service_name}' AND filePath ='/root/logs/${each.key}_log.txt' AND message LIKE '%running snapshot export%'"
}

resource "newrelic_events_to_metrics_rule" "generate_snapshot_success_metrics" {
  account_id = var.new_relic_account_id
  for_each   = toset(["mainnet", "calibnet"])

  name        = format("%s %s snapshot generation success", var.service_name, each.key)
  description = "Success snapshot generations"
  nrql        = "From Log select uniqueCount(message) as '${var.service_name}.${each.key}.snapshot_generation_ok' WHERE `hostname` = '${var.service_name}' AND filePath ='/root/logs/${each.key}_log.txt' AND message LIKE '%Snapshot uploaded for%'"
}

resource "newrelic_events_to_metrics_rule" "generate_snapshot_fail_metrics" {
  account_id = var.new_relic_account_id
  for_each   = toset(["mainnet", "calibnet"])

  name        = format("%s %s snapshot generation failure", var.service_name, each.key)
  description = "Failed snapshot generations"
  nrql        = "From Log select uniqueCount(message) as '${var.service_name}.${each.key}.snapshot_generation_fail' WHERE `hostname` = '${var.service_name}' AND filePath ='/root/logs/${each.key}_log.txt' AND message LIKE '%Snapshot upload failed for%'"
}

data "newrelic_test_grok_pattern" "grok"{
    grok        = "\\[%%{TIMESTAMP_ISO8601:event_timestamp}\\] %%{GREEDYDATA:event}"
    log_lines   = ["[2024-01-25T17:06:16] snapshot uploaded"]
}
resource "newrelic_log_parsing_rule" "service_event_parsing_rule"{
    for_each   = toset(["mainnet", "calibnet"])
    name        = "${var.service_name} ${each.key} event log_parse_rule"
    attribute   = "message"
    enabled     = true
    lucene      = "filePath = '/root/logs/*_events.log"
    grok        = data.newrelic_test_grok_pattern.grok.grok
    nrql        = "SELECT * from Log WHERE hostname = '${var.service_name}' AND filePath = '/root/logs/${each.key}_events.log'"
    matched     = data.newrelic_test_grok_pattern.grok.test_grok[0].matched
}
