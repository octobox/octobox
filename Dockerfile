FROM ruby:2.6.0-alpine

ENV APP_ROOT /usr/src/app
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
 && bundle config --global frozen 1 \
 && bundle install --without test --jobs 2 \
 && gem install foreman

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
