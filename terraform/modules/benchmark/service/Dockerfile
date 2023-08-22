FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required forest and lotus packages
RUN apt-get update && \
    apt-get install --no-install-recommends -y ruby ruby-dev make gcc git golang rustc cargo s3cmd clang aria2 zstd git-lfs time \
    bzr jq pkg-config ocl-icd-libopencl1 ocl-icd-dev llvm wget hwloc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install required Ruby gems
RUN gem install slack-ruby-client sys-filesystem bundler concurrent-ruby deep_merge tomlrb toml-rb csv droplet_kit

WORKDIR /chainsafe

COPY . .
COPY ruby_common ruby_common
