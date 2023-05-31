#!/bin/bash

## Install dependencies
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io
dnf install -y docker-buildx-plugin docker-compose-plugin docker-compose
dnf install -y ruby
dnf install -y ruby-devel
dnf install -y gcc make
dnf clean all
gem install slack-ruby-client
gem install sys-filesystem

nohup /bin/bash ./run_service.sh > run_service_log.txt &
