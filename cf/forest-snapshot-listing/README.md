# Snapshot listing worker

This worker acts on endpoints at `https://forest-archive.chainsafe.dev/list**` and will list objects with `diff`, `lite`, and `latest` prefixes.

# Local deployment

First, login to Cloudflare with `wrangler login`. Then, use `wrangler dev --remote` to deploy a local version of this worker which will use the `forest-archive-dev` bucket rather than the production `forest-archive` bucket. Merging changes to this worker will automatically deploy them.
