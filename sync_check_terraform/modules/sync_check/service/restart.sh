#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

## Start Sync Check Service:
/bin/bash ./run_service.sh
