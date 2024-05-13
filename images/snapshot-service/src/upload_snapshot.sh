#!/bin/bash

# If Forest hasn't synced to the network after 6 hours, something has gone wrong.
SYNC_TIMEOUT=6h

if [[ $# != 3 ]]; then
  echo "Usage: bash $0 CHAIN_NAME LOG_EXPORT_DAEMON LOG_EXPORT_METRICS"
  exit 1
fi

CHAIN_NAME=$1
LOG_EXPORT_DAEMON=$2
LOG_EXPORT_METRICS=$3

# Make sure we have the most recent Forest image
docker pull ghcr.io/chainsafe/forest:"${FOREST_TAG}"

# Sync and export is done in a single container to make sure everything is
# properly cleaned up.
COMMANDS=$(cat << HEREDOC
set -eux

# Install utility binaries that do not come with the image.
# This assumes the container was started as a superuser.
apt-get update && apt-get install -y curl aria2

# Switch back to the service user for other service commands.
su - forest

function add_timestamps {
  while IFS= read -r line; do
    echo "\$(date +'%Y-%m-%d %H:%M:%S') \$line"
  done
}

# periodically write metrics to a file
# this is done in a separate process to avoid blocking the sync process
# and to ensure that the metrics are written even if it crashes
function write_metrics {
  while true; do
    {
      curl --silent --fail --max-time 5 --retry 5 --retry-delay 2 --retry-max-time 10 http://localhost:6116/metrics || true
    } | add_timestamps >> "$LOG_EXPORT_METRICS"
    sleep 15
  done
}

function print_forest_logs {
  cat forest.err forest.out > $LOG_EXPORT_DAEMON
}
trap print_forest_logs EXIT

echo "[client]" > config.toml
echo 'data_dir = "/home/forest/forest_db"' >> config.toml
echo 'encrypt_keystore = false' >> config.toml

echo "Chain: $CHAIN_NAME"

# spawn a task in the background to periodically write Prometheus metrics to a file
(
  set +x  # Disable debugging for this subshell to keep the logs clean.
  write_metrics
) &

forest-tool db destroy --force --config config.toml --chain "$CHAIN_NAME"

# Workaround for https://github.com/ChainSafe/forest/issues/3715
# Normally, Forest should automatically download the latest snapshot. However, the performance
# of the download gets randomly bad, and the download times out.
# Retry logic, because CF occassionally returns 500 (not 503) errors.
for i in {1..5}; do aria2c -x5 https://forest-archive.chainsafe.dev/latest/$CHAIN_NAME/ && break || sleep 15; done

forest --config config.toml --chain "$CHAIN_NAME" --consume-snapshot *.car.zst --halt-after-import

forest --config config.toml --chain "$CHAIN_NAME" --no-gc --save-token=token.txt --target-peer-count 500 --detach
timeout "$SYNC_TIMEOUT" forest-cli sync wait
forest-cli snapshot export -o forest_db/
forest-cli --token=\$(cat token.txt) shutdown --force

# Snapshot is exported, remove the Forest DB to limit space usage.
forest-tool db destroy --force --config config.toml --chain "$CHAIN_NAME"

# Run full checks only for calibnet, given that it takes too long for mainnet.
if [ "$CHAIN_NAME" = "calibnet" ]; then
  timeout 30m forest-tool snapshot validate --check-network "$CHAIN_NAME" forest_db/forest_snapshot_*.forest.car.zst
else
  forest-tool archive info forest_db/forest_snapshot_*.forest.car.zst
  timeout 30m forest-tool snapshot validate --check-links 0 --check-network "$CHAIN_NAME" --check-stateroots 5 forest_db/forest_snapshot_*.forest.car.zst
fi

# Kill the metrics writer process
kill %1

HEREDOC
)

# Stop any lingering docker containers
CONTAINER_NAME="forest-snapshot-upload-node-$CHAIN_NAME"
docker stop "$CONTAINER_NAME" || true
docker rm --force "$CONTAINER_NAME"

# Cleanup volumes from the previous if any.
DB_VOLUME="${CHAIN_NAME}_db"
LOG_VOLUME="${CHAIN_NAME}_logs"
docker volume rm "${DB_VOLUME}" || true
docker volume rm "${LOG_VOLUME}" || true

# Run forest and generate a snapshot in the `DB_VOLUME` volume.
docker run \
  --name "$CONTAINER_NAME" \
  --user root \
  -v "${DB_VOLUME}:/home/forest/forest_db" \
  -v "${LOG_VOLUME}:/home/forest/logs" \
  --entrypoint /bin/bash \
  ghcr.io/chainsafe/forest:"${FOREST_TAG}" \
  -c "$COMMANDS"

generation_result=$?

# Copy the logs to the current container. Mounting won't work because it would use the real host's filesystem.
docker cp "$CONTAINER_NAME":/home/forest/logs/. "$(dirname "$LOG_EXPORT_DAEMON")"
docker rm --force "$CONTAINER_NAME"

if [[ $generation_result != 0 ]]; then
  echo "Snapshot generation failed"
  exit 1
fi

# Mount the snapshot volume and copy the snapshot and corresponding shasum to the S3 bucket.
docker run -v "${DB_VOLUME}:/opt/snapshots" --entrypoint /bin/bash \
  --env AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY" \
  --env AWS_SECRET_ACCESS_KEY="$R2_SECRET_KEY" \
  public.ecr.aws/aws-cli/aws-cli:2.15.18 \
  -c 'aws configure set default.s3.multipart_chunksize 4GB && \
      ls /opt/snapshots/forest_snapshot_'"${CHAIN_NAME}"'*.forest.car* | while read file; do \
          echo "Uploading $file to S3..." && \
          aws --endpoint '"${R2_ENDPOINT}"' s3 cp --no-progress $file "s3://'"${SNAPSHOT_BUCKET}"'/'"${CHAIN_NAME}"'/latest/" || exit 1; \
      done'


docker volume rm "${DB_VOLUME}" || true
