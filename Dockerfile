FROM ruby:2.5.0-alpine
RUN apk add --update \
  build-base \
  netcat-openbsd \
  git \
  nodejs \
  postgresql-dev \
  mysql-dev \
  tzdata \
  curl-dev \
  && rm -rf /var/cache/apk/*
# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock /usr/src/app/
RUN bundle install --without test production --jobs 2

COPY . /usr/src/app
# Generate API Docs
RUN RAILS_ENV=development bin/rails api_docs:generate

# Allow the image to run with an arbitrary uid, but gid set to 0 (the OpenShift case)
RUN chgrp -R 0 /usr/src/app \
 && chmod -R g=u /usr/src/app

CMD ["bin/docker-start"]
