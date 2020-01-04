#!/bin/sh
set -e

db_host=${OCTOBOX_DATABASE_HOST:-database.service.octobox.internal}
while ! nc -z $db_host ${OCTOBOX_DATABASE_PORT:-5432}; do
  echo "Waiting for database to be available..."
  sleep 1
done

bundle exec rake db:migrate
rm -rf tmp/pids

env_boolean() {
  local env=$1
  if [ "$env" == "true" ] || [ "$env" == "1" ]; then
    return 0
  else
    return 1
  fi
}

if env_boolean "${OCTOBOX_SIDEKIQ_SCHEDULE_ENABLED}" ||
   env_boolean "${OCTOBOX_BACKGROUND_JOBS_ENABLED}";
then
  exec foreman start -f config/Procfile.foreman -d .
else
  exec bundle exec rails s -b 0.0.0.0
fi
