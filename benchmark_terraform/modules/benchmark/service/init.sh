#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    sudo dnf install -y docker docker-compose
    sudo systemctl enable docker
    sudo systemctl start docker
fi

# Run Docker Compose using the provided file which runs the benchmark
docker-compose -f docker-compose.yml up -d --force-recreate
