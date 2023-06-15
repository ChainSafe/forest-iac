#!/bin/bash

## Enable strict error handling, command tracing, and pipefail
set -euxo pipefail

## Install dependencies
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && \
dnf install -y dnf-plugins-core docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose ruby ruby-devel gcc make aria2 zstd clang clang-devel cmake && \
dnf install -y git bzr jq pkgconfig mesa-libOpenCL mesa-libOpenCL-devel opencl-headers ocl-icd ocl-icd-devel llvm wget hwloc hwloc-devel golang rust cargo s3cmd
dnf clean all
gem install slack-ruby-client sys-filesystem bundler concurrent-ruby deep_merge tomlrb toml-rb csv fileutils logger open3 optparse set tmpdir

## Start benchmark
ruby run_benchmark.rb
