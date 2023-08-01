#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

## Start Sync Check Service:
bash ./run_service.sh
