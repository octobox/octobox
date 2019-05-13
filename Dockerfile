FROM ruby:2.6.3-alpine as base

ENV APP_ROOT /usr/src/app
WORKDIR $APP_ROOT

RUN gem install bundler \
 && apk add --no-cache \
    netcat-openbsd \
    git \
    nodejs \
    postgresql-dev \
    mysql-dev \
    tzdata \
    curl-dev

# Will invalidate cache as soon a the Gemfile changes
COPY Gemfile Gemfile.lock $APP_ROOT/

# * Setup system
# * Install common Ruby dependencies
RUN apk add --no-cache build-base \
 && gem install bundler foreman \
 && bundle config --global frozen 1 \
 && bundle install \
    --without development test production \
    --jobs $(grep -c ^processor /proc/cpuinfo) \
 && apk del build-base

# Startup
CMD ["bin/docker-start"]

####################

FROM base as development

# * Install development dependencies
RUN apk add --no-cache build-base \
 && bundle install \
    --with development \
    --without test production \
    --jobs $(grep -c ^processor /proc/cpuinfo) \
 && apk del build-base

# Copy application code
COPY . $APP_ROOT

# * Generate the docs
# * Make files OpenShift conformant
RUN RAILS_ENV=development bin/rails api_docs:generate \
 && chown -R 1000:0 $APP_ROOT \
 && chmod -R g=u $APP_ROOT

USER 1000

####################

FROM base as production

# * Install production dependencies
RUN apk add --no-cache build-base \
 && bundle install \
    --with production \
    --without development test \
    --jobs $(grep -c ^processor /proc/cpuinfo) \
 && apk del build-base

# Copy application code
COPY . $APP_ROOT

# Precompile assets for a production environment.
# This is done to include assets in production images on Dockerhub.
RUN RAILS_ENV=production rake assets:precompile \
 && rm -rf /usr/src/app/tmp/cache/

# * Make files OpenShift conformant
RUN chown -R 1000:0 $APP_ROOT/ \
 && chmod -R g=u $APP_ROOT/

VOLUME $APP_ROOT/public/

USER 1000
