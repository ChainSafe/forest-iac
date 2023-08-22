FROM fedora:38

RUN dnf -y install dnf-plugins-core && \
    dnf -y install \
        ruby-3.2.2 ruby-devel-3.2.2 make-4.4 gcc-13.2.1 git-2.41.0 golang-1.20.7 rust-1.71.1 cargo-1.71.1 s3cmd-2.3.0 clang-16.0.6 aria2-1.36.0 zstd-1.5.5 clang-devel-16.0.6 git-lfs-3.4.0 time-1.9 && \
    dnf clean all

# Lotus dependencies with versions
RUN dnf -y install \
        breezy-3.2.2 jq-1.6 pkgconf-pkg-config-1.8.0 mesa-libOpenCL-23.1.6 mesa-libOpenCL-devel-23.1.6 opencl-headers-3.0 ocl-icd-2.3.2 ocl-icd-devel-2.3.2 llvm-16.0.6 wget-1.21.3 hwloc-2.5.0 hwloc-devel-2.5.0 && \
    dnf clean all

RUN gem install slack-ruby-client sys-filesystem bundler concurrent-ruby deep_merge tomlrb toml-rb csv fileutils logger open3 optparse set tmpdir droplet_kit

WORKDIR /chainsafe

COPY . .
COPY ruby_common ruby_common
