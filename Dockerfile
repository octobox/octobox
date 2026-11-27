FROM ruby:4.0.10-alpine AS base

ENV APP_ROOT=/usr/src/app
ENV OCTOBOX_DATABASE_PORT=5432
ENV RUBY_YJIT_ENABLE=1
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
WORKDIR $APP_ROOT

RUN apk add --no-cache \
    netcat-openbsd \
    git \
    nodejs \
    libpq \
    libcurl \
    libstdc++ \
    tzdata \
    gcompat \
    jemalloc \
 && bundle config --global frozen 1 \
 && chmod g=u $APP_ROOT

FROM base AS build

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    curl-dev \
    yaml-dev \
    libffi-dev \
    rust \
    cargo \
    clang-dev

COPY Gemfile Gemfile.lock $APP_ROOT/

RUN gem install bundler foreman \
 && bundle config set without 'test development' \
 && bundle config set force_ruby_platform true \
 && bundle install --jobs "$(nproc)" \
 && rm -rf /usr/local/bundle/cache/*.gem

COPY . $APP_ROOT

# OpenShift runs the container as an arbitrary user in group 0
RUN RAILS_ENV=production bundle exec rake assets:precompile \
 && RAILS_ENV=development bin/rails api_docs:generate \
 && rm -rf tmp/cache/assets \
 && chgrp -R 0 $APP_ROOT \
 && chmod -R g=u $APP_ROOT

FROM base

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build $APP_ROOT $APP_ROOT

CMD ["bin/docker-start"]
