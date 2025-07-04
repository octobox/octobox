FROM ruby:3.4.5-alpine AS builder

ENV APP_ROOT=/usr/src/app
WORKDIR $APP_ROOT

# =============================================
# Build layer

# Will invalidate cache as soon as the Gemfile changes
COPY Gemfile Gemfile.lock $APP_ROOT/

# * Setup system
# * Install Ruby dependencies
RUN apk add --update \
    build-base \
    git \
    postgresql-dev \
    curl-dev \
    yaml-dev \
    libffi-dev \
    gcompat \
    rust \
    cargo \
    clang-dev \
 && rm -rf /var/cache/apk/* \
 && gem update --system \
 && gem install bundler \
 && bundle config --global frozen 1 \
 && bundle config set without 'test development' \
 && bundle config set force_ruby_platform true \
 && bundle install --jobs 2

FROM ruby:3.4.5-alpine

ENV APP_ROOT=/usr/src/app
ENV OCTOBOX_DATABASE_PORT=5432
WORKDIR $APP_ROOT

# =============================================
# System layer

# Will invalidate cache as soon as the Gemfile changes
COPY Gemfile Gemfile.lock $APP_ROOT/
COPY --from=builder /usr/local/bundle /usr/local/bundle

# * Setup system
# * Install Ruby dependencies
RUN apk add --update \
    netcat-openbsd \
    git \
    nodejs \
    postgresql-dev \
    tzdata \
    gcompat \
 && rm -rf /var/cache/apk/* \
 && gem update --system \
 && gem install bundler foreman \
 && bundle config --global frozen 1 \
 && bundle config set without 'test development'

# ========================================================
# Application layer

# Copy application code
COPY . $APP_ROOT

# Precompile assets for a production environment.
# This is done to include assets in production images on Dockerhub.
RUN RAILS_ENV=production bundle exec rake assets:precompile

# * Generate the docs
# * Make files OpenShift conformant
RUN RAILS_ENV=development bin/rails api_docs:generate \
 && chgrp -R 0 $APP_ROOT \
 && chmod -R g=u $APP_ROOT

# Startup
CMD ["bin/docker-start"]
