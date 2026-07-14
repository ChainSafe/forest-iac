# Build the native gem extensions in a throwaway stage so the runtime image
# ships without a compiler toolchain.
FROM ruby:4.0-slim AS gems
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV BUNDLE_FROZEN=true BUNDLE_PATH=/bundle
COPY Gemfile Gemfile.lock ./
RUN bundle install

FROM ruby:4.0-slim
WORKDIR /app
ENV BUNDLE_PATH=/bundle
COPY --from=gems /bundle /bundle
COPY Gemfile Gemfile.lock check_rpc.rb ./
ENTRYPOINT ["bundle", "exec", "ruby", "check_rpc.rb"]
