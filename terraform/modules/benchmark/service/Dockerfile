FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND noninteractive

# Update the package repository and install necessary packages
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    ruby ruby-dev make gcc golang git curl wget pkg-config clang build-essential \
    mesa-opencl-icd ocl-icd-opencl-dev hwloc libhwloc-dev s3cmd aria2 zstd time && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install required Ruby gems using Bundler
RUN gem install bundler slack-ruby-client sys-filesystem concurrent-ruby deep_merge tomlrb toml-rb csv droplet_kit 

# Download and install Rust using rustup
RUN curl --proto '=https' --tlsv1.2 -sSf -o rustup.sh https://sh.rustup.rs && sh rustup.sh -y
# Set the Rust environment variables
ENV PATH="/root/.cargo/bin:$PATH"

WORKDIR /chainsafe

COPY . .
COPY ruby_common ruby_common
