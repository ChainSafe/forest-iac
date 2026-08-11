# Build the native gem extensions in a throwaway stage so the runtime image
# ships without a compiler toolchain.
FROM ruby:4.0-alpine AS gems
RUN apk add --no-cache build-base
WORKDIR /app
ENV BUNDLE_FROZEN=true BUNDLE_PATH=/bundle
COPY Gemfile Gemfile.lock ./
RUN bundle install

FROM ruby:4.0-alpine

WORKDIR /app
ENV BUNDLE_PATH=/bundle
COPY --from=gems /bundle /bundle
COPY Gemfile Gemfile.lock check_rpc.rb ./
ENTRYPOINT ["bundle", "exec", "ruby", "check_rpc.rb"]
