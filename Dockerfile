FROM ruby:2.4.1-alpine
RUN apk add --update \
  build-base \
  netcat-openbsd \
  git \
  nodejs \
  postgresql-dev \
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
