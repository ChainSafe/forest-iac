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

## Start docker daemon
systemctl start docker

## Setup volume
docker volume create --name=forest-data
docker volume create --name=sync-check
docker volume create --name=ruby-common

## We need it to access the DATA_DIR regardless of the user.
chmod 0777 /var/lib/docker/volumes/forest-data/_data

## Copy all relevant scripts
cp -R /root/* /var/lib/docker/volumes/sync-check/_data/
cp -R /root/ruby_common/* /var/lib/docker/volumes/ruby-common/_data/
