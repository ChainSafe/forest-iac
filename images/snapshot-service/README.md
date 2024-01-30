# Forest snapshot service

This service serves as a Filecoin snapshot generator and uploader. Supported networks are [calibnet](https://docs.filecoin.io/networks/calibration) and [mainnet](https://docs.filecoin.io/networks/mainnet). All S3-compatible providers should work correctly, though it was tested exclusively on Cloudflare R2.

## Building the image

```bash
docker build --build-context common=../../tf-managed/scripts/ -t <name>:<tag> .
```

## Running the Forest snapshot service

The container needs additional privileges and access to the docker socket to issue other `docker` commands.

This command will generate a snapshot for the given network and upload it to an S3 bucket.
```bash
docker run --privileged -v /var/run/docker.sock:/var/run/docker.sock --rm --env-file <variable-file> --env NETWORK_CHAIN=<chain> ghcr.io/chainsafe/forest-snapshot-service:edge
```

## Variables (all required)

```bash
# Details for the snapshot upload
R2_ACCESS_KEY=
R2_SECRET_KEY=
R2_ENDPOINT=
SNAPSHOT_BUCKET=

# Details for the Slack notifications
SLACK_API_TOKEN=
SLACK_NOTIFICATION_CHANNEL=

# Network chain - can be either `mainnet` or `calibnet`
NETWORK_CHAIN=
# Forest tag to use. `latest` is the newest stable version.
# See [Forest packages](https://github.com/ChainSafe/forest/pkgs/container/forest) for more.
FOREST_TAG=
```
