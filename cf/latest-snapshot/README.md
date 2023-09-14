# Snapshot redirect worker

This worker acts on two endpoints:

- `https://forest-archive.chainsafe.dev/latest/calibnet/`
- `https://forest-archive.chainsafe.dev/latest/mainnet/`

These links will download the latest available snapshot for calibnet and mainnet, respectively.

# Local deployment

Use `wrangler dev` to deploy a local version of this worker which will use the `forest-archive-dev` bucket rather than the production `forest-archive` bucket. Merging changes to this worker will automatically deploy them.
