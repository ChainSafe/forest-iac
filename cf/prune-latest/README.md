# Deployment

This worker is automatically deployed when modified. To test locally, run `wrangler dev`. This will run the worker against the development bucket `forest-archive-dev`. Once the worker is deployed to production, it'll use the `forest-archive` bucket.

# Pruning

We upload new Filecoin snapshots to CloudFlare every hour and keep only the 10 most recent. The CloudFlare worker script is triggered automatically every hour.
