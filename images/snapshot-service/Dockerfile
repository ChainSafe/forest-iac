# Snapshot service Dockerfile.
# It is meant to produce a single snapshot of the given chain in the Filecoin network and upload it to S3 (preferably Cloudflare R2, it should work for other providers as well, but it wasn't tested).
FROM docker:24
LABEL org.opencontainers.image.description "Forest snapshot service generator and uploader for Filecoin"

RUN apk add --no-cache \
        ruby=3.2.2-r1 \
        ruby-dev=3.2.2-r1 \
        docker=24.0.7-r0 \
        aws-cli=2.13.25-r0 \
        bash=5.2.21-r0 && \
    gem install \
        docker-api:1.28.0 \
        slack-ruby-client:2.2 \
        activesupport:7.0.8

COPY ./src /opt/snapshot-service

# `common` is defined via the `--build-context` flag in the `docker build` command, e.g.,
# `docker build --build-context common=../../tf-managed/scripts/ -t ghcr.io/chainsafe/forest-snapshot-service:latest .`
# TODO: Change this once `sync-check` is fully-dockerized as well.
# hadolint ignore=DL3022
COPY --from=common ruby_common /opt/snapshot-service/ruby_common

WORKDIR /opt/snapshot-service

CMD ["bash", "run.sh"]
