# Snapshot monitoring

This module creates New Relic resources to check the status of the global snapshot service. Note that this does not check the status of the [snapshot-service](../daily-snapshot), but rather the actual snapshots (and the epochs at which they were produced), available at:
- <https://forest-archive.chainsafe.dev/mainnet/latest/>
- <https://forest-archive.chainsafe.dev/calibnet/latest/>

The logic is contained in the [snapshot-age-monitor](./snapshot-age-monitor.js).

Networks: `mainnet` and `calibnet`
Checks:
- asserts the epoch of the hosted snapshots is not older than a given threshold,
- trigger alarms if more than 2/3 checks over an hour fail.

## Alarm destinations

All alarms are handled via NewRelic, which integrates other applications. For now, it's:
* [PagerDuty](https://chainsafe.pagerduty.com/) - the provided destination is linked with a service generated there and visible in the [service direcory](https://chainsafe.pagerduty.com/service-directory). It will fire alarms to on-call engineers if enabled, so use it cautiously.
* [Slack](https://api.slack.com/) - the provided destination is also linked with company Slack, and the `channel_id` governs the actual channel to which the notifications will go.
