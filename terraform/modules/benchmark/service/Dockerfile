FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND noninteractive

# Install necessary forest and lotus packages
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    ruby ruby-dev make gcc git curl wget pkg-config clang build-essential \
    mesa-opencl-icd ocl-icd-opencl-dev hwloc libhwloc-dev s3cmd aria2 zstd time bzr jq pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install Rust using rustup
RUN curl --proto '=https' --tlsv1.2 -sSf -o rustup.sh https://sh.rustup.rs && sh rustup.sh -y
# Set the Rust environment variables
ENV PATH="/root/.cargo/bin:$PATH"

# Download and install Go
RUN curl -o /tmp/go.tar.gz -L https://go.dev/dl/go1.20.7.linux-amd64.tar.gz && \
    tar -xz -C /usr/local -f /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz
# Set the Go environment variables
RUN echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
ENV PATH="/usr/local/go/bin:$PATH"

WORKDIR /chainsafe

# Copy all required files
COPY . .
COPY ruby_common ruby_common

# Install required Ruby gems
RUN gem install bundler && bundle install
