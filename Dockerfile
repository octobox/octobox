FROM ruby:2.5.1-alpine

# Install and update all dependencies (os, ruby)
WORKDIR /usr/src/app

# =============================================
# System layer

# Will invalidate cache as soon a the Gemfile changes
COPY Gemfile Gemfile.lock /usr/src/app/

# * Setup system
# * Install Ruby dependencies
RUN apk add --update \
    build-base \
    netcat-openbsd \
    git \
    nodejs \
    postgresql-dev \
    mysql-dev \
    tzdata \
    curl-dev \
    libidn-dev \
 && rm -rf /var/cache/apk/* \
 && bundle config --global frozen 1 \
 && bundle install --without test production --jobs 2 \
 && gem install foreman

# ========================================================
# Application layer

# Copy application code
COPY . /usr/src/app

# * Generate the docs
# * Make files OpenShift conformant
RUN RAILS_ENV=development bin/rails api_docs:generate \
 && chgrp -R 0 /usr/src/app \
 && chmod -R g=u /usr/src/app

# Startup
CMD ["bin/docker-start"]
