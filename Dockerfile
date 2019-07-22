FROM ruby:2.6.3-alpine

ENV APP_ROOT /usr/src/app
ENV OCTOBOX_DATABASE_PORT 5432
WORKDIR $APP_ROOT

# =============================================
# System layer

# Will invalidate cache as soon as the Gemfile changes
COPY Gemfile Gemfile.lock $APP_ROOT/

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
 && rm -rf /var/cache/apk/* \
 && gem install bundler foreman \
 && bundle config --global frozen 1 \
 && bundle install --without test --jobs 2

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
