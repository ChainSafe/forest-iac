# Snapshot redirect worker

This worker acts on two endpoints:

- `https://forest-internal.chainsafe.dev/latest/calibnet/`
- `https://forest-archive.chainsafe.dev/latest/mainnet/`

- `https://forest-internal.chainsafe.dev/archive/calibnet/*`
- `https://forest-internal.chainsafe.dev/archive/mainnet/*`
- `https://forest-internal.chainsafe.dev/archive/historical/*`

These links will download the latest available snapshot for calibnet and mainnet, respectively.

# Local deployment

First, login to Cloudflare with `wrangler login`. Then, use `wrangler dev --remote` to deploy a local version of this worker which will use the `forest-archive-dev` bucket rather than the production `forest-archive` bucket. Merging changes to this worker will automatically deploy them.
