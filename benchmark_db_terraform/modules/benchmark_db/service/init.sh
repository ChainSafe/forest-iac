#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

## Install dependencies
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && \
dnf install -y dnf-plugins-core docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose ruby ruby-devel gcc make aria2 zstd clang clang-devel cmake && \
dnf install -y git bzr jq pkgconfig mesa-libOpenCL mesa-libOpenCL-devel opencl-headers ocl-icd ocl-icd-devel llvm wget hwloc hwloc-devel golang rust cargo s3cmd
dnf clean all
gem install slack-ruby-client sys-filesystem bundler concurrent-ruby deep_merge tomlrb toml-rb csv fileutils logger open3 optparse set tmpdir

## Configure s3cmd
s3cmd --dump-config \
    --host="$BENCHMARK_ENDPOINT" \
    --host-bucket="%(bucket)s.$BENCHMARK_ENDPOINT" \
    --access_key="$AWS_ACCESS_KEY_ID" \
    --secret_key="$AWS_SECRET_ACCESS_KEY" \
    --multipart-chunk-size-mb=4096 > ~/.s3cfg

## Run benchmark
ruby bench.rb --chain calibnet --tempdir ./benchmark --daily

## Upload benchmark result to s3
s3cmd --acl-public put "/root/results_*.csv" s3://"$BENCHMARK_BUCKET"/benchmark-results/ || exit 1
