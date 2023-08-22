FROM fedora:38

RUN dnf -y install dnf-plugins-core && \
    dnf -y install \
        ruby-2.7.4 ruby-devel-2.7.4 make-4.3 gcc-11 git-2.33.1 golang-1.17 rust-1.55 cargo-1.55 s3cmd-2.1.0 clang-13 aria2-1.36.0 zstd-1.5.0 clang-devel-13 git-lfs-3.0.1 time-1.9 && \
    dnf clean all

# Lotus dependencies with versions
RUN dnf -y install \
        bzr-2.8.0 jq-1.6 pkgconfig-0.29.2 mesa-libOpenCL-21.0.2 mesa-libOpenCL-devel-21.0.2 opencl-headers-2021.03.25 ocl-icd-2.3.1 ocl-icd-devel-2.3.1 llvm-13 wget-1.23.1 hwloc-2.5.0 hwloc-devel-2.5.0 && \
    dnf clean all

RUN gem install slack-ruby-client sys-filesystem bundler concurrent-ruby deep_merge tomlrb toml-rb csv fileutils logger open3 optparse set tmpdir droplet_kit

WORKDIR /chainsafe

COPY . .
COPY ruby_common ruby_common
