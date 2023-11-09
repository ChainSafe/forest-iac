# Snapshot redirect worker

This worker acts on endpoint in form of:

- `https://forest-archive.chainsafe.dev/calibnet/*`
- `https://forest-archive.chainsafe.dev/mainnet/*`
- `https://forest-archive.chainsafe.dev/historical/*`

you can use it to redirect to the latest snapshot for a given R2 bucket. For example:

- `https://forest-archive.chainsafe.dev/calibnet/lite/forest_snapshot_calibnet_2022-11-01_height_0.forest.car.zst`

These links will download the latest available snapshot for calibnet and mainnet, respectively.

# Local deployment

Use `wrangler dev --remote` to deploy a local version of this worker which will use the `forest-archive-dev` bucket rather than the production `forest-archive` bucket. Merging changes to this worker will automatically deploy them.
