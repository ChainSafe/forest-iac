FROM fedora:38

RUN dnf -y install dnf-plugins-core && \
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && \
    dnf install -y \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
        ruby ruby-devel make gcc git golang rust cargo s3cmd clang aria2 zstd clang-devel cmake && \
    dnf clean all

# Lotus dependencies
RUN dnf -y install bzr jq pkgconfig mesa-libOpenCL mesa-libOpenCL-devel opencl-headers ocl-icd ocl-icd-devel llvm wget hwloc hwloc-devel && \
    dnf clean all


RUN gem install slack-ruby-client sys-filesystem bundler concurrent-ruby deep_merge tomlrb toml-rb csv fileutils logger open3 optparse set tmpdir droplet_kit

WORKDIR /chainsafe

COPY . .
COPY ruby_common ruby_common
