#!/bin/bash

# Script to check health status of a running node.
# The only prerequisite here is that the `forest` process is running.
# The script will wait till metrics endpoint becomes available.
# Input: Forest hostname

# Exit codes
RET_OK=0
RET_SYNC_TIPSET_STALE=1
RET_SYNC_ERROR=2
RET_SYNC_TIMEOUT=3
RET_HOSTNAME_NOT_SET=4

if [ $# -eq 0 ]; then
    echo "No arguments supplied. Need to provide Forest hostname, e.g. forest-mainnet."
    exit "$RET_HOSTNAME_NOT_SET"
fi

# Governs how long the health check will run to assert Forest condition
HEALTH_CHECK_DURATION_SECONDS=${HEALTH_CHECK_DURATION_SECONDS:-"360"}
# Forest metrics endpoint path
FOREST_METRICS_ENDPOINT=${FOREST_METRICS_ENDPOINT:-"http://$1:6116/metrics"}
# Initial sync timeout (in seconds) after which the health check will fail
HEALTH_CHECK_SYNC_TIMEOUT_SECONDS=${HEALTH_CHECK_SYNC_TIMEOUT_SECONDS:-"7200"}

# Extracts metric value from the metric data
# Arg: name of the metric
function get_metric_value() {
  grep -E "^$1" <<< "$metrics" | cut -d' ' -f2
}

# Updates metrics data with the latest metrics from Prometheus
# Arg: none
function update_metrics() {
  metrics=$(curl --silent "$FOREST_METRICS_ENDPOINT")
}

# Checks if an error occurred and is visible in the metrics.
# Arg 1: name of the error metric
# Arg 2: maximum number of occurrences for the assertion to pass (0 for strictly not pass)
function assert_error() {
  errors="$(get_metric_value "$1")"
  if [[ "$errors" -gt "$2" ]]; then
    echo "❌ $1: $errors (max: $2)"
    ret=$RET_SYNC_ERROR
  fi
}

##### Actual script

# Wait for Forest to start syncing
# Excluding `tipset_start` from the unbound variable check
set +u
timeout="$HEALTH_CHECK_SYNC_TIMEOUT_SECONDS"
echo "⏳ Waiting for Forest to start syncing (up to $timeout seconds)..."
until [ -n "$tipset_start" ] || [ "$timeout" -le 0 ]
do
  update_metrics
  tipset_start="$(get_metric_value "head_epoch")"
  sleep 1
  timeout=$((timeout-1))
done
# Re-enabling the unbound variable check
set -u

if [ "$timeout" -le 0 ]; then
  echo "❌ Timed out on sync wait"
  exit "$RET_SYNC_TIMEOUT"
fi
echo "✅ Forest started syncing"

# Let Forest run for the health check period
echo "⏳ Waiting for the health probe to finish..."
sleep "$HEALTH_CHECK_DURATION_SECONDS"

# Grab last synced tipset epoch
update_metrics
tipset_end="$(get_metric_value "head_epoch")"

if [ -z "$tipset_end" ]; then
  echo "❌ Did not manage to get sync status"
  exit "$RET_SYNC_ERROR"
fi

# Assert tipset epoch moved forward
echo "👉 Tipset start: $tipset_start, end: $tipset_end"
if [ "$tipset_end" -gt "$tipset_start" ]; then
  echo "✅ Tipset epoch moving forward"
  ret="$RET_OK"
else
  echo "❌ Tipset epoch didn't move forward."
  ret="$RET_SYNC_TIPSET_STALE"
fi

# Assert there are no sync errors
assert_error "network_head_evaluation_errors" 0
assert_error "bootstrap_errors" 2
assert_error "follow_network_interruptions" 0
assert_error "follow_network_errors" 0

if [ "$ret" -ne "$RET_SYNC_ERROR" ]; then
  echo "✅ No sync errors"
fi

if [ "$ret" -eq "$RET_OK" ]; then
  echo "✅ Health check passed"
else
  echo "❌ Health check failed"
fi

exit "$ret"
