#!/bin/bash

set -euxo pipefail

s3cmd --acl-public put "$BASE_FOLDER/forest_db/forest_snapshot_$CHAIN_NAME"* s3://"$SNAPSHOT_BUCKET"/"$CHAIN_NAME"/