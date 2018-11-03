FROM pawurb/ruby-jemalloc-node-yarn:latest

# Install and update all dependencies (os, ruby)
WORKDIR /usr/src/app

# =============================================
# System layer

# Will invalidate cache as soon a the Gemfile changes
COPY Gemfile Gemfile.lock /usr/src/app/

# * Setup system
# * Install Ruby dependencies
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-base \
    netcat-openbsd \
    git \
    nodejs \
    postgresql-dev \
    mysql-dev \
    tzdata \
    curl-dev \
 && apt-get clean \
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
CMD ["bin/run-dev.sh"]
