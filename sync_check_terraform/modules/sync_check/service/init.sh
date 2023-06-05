#!/bin/bash -euxo pipefail

## Install dependencies
dnf install -y dnf-plugins-core && \
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && \
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose ruby ruby-devel gcc make && \
dnf clean all
gem install slack-ruby-client sys-filesystem

nohup /bin/bash ./run_service.sh > run_service_log.txt &
