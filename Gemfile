source 'https://rubygems.org'
ruby '2.5.1'

gem 'rails', '~> 5.2'
gem 'bootstrap'
gem "attr_encrypted", "~> 3.1.0"
gem 'jquery-rails'
gem 'kaminari'
gem 'local_time'
gem 'octicons_helper'
gem 'octokit'
gem 'omniauth-github'
gem 'puma'
gem 'sassc-rails'
gem 'turbolinks'
gem 'typhoeus'
gem 'faraday_middleware'
gem 'uglifier'
gem 'pg_search'
gem 'jbuilder'
gem 'rake'
gem 'git'
gem 'rgb'
gem 'sidekiq'
gem 'sidekiq-unique-jobs'
gem 'sidekiq-scheduler'
gem 'rack-canonical-host'
gem 'gemoji'
gem 'bootsnap', require: false
gem 'bugsnag'

# Supported databases
gem 'mysql2', require: false
gem 'pg', '1.0.0', require: false

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem 'rails-controller-testing'
  gem 'sql_queries_count'
end

group :test do
  gem 'factory_bot'
  gem 'simplecov'
  gem 'codeclimate-test-reporter'
  gem 'webmock'
  gem 'mocha'
  gem 'minitest'
end

group :development do
  gem 'web-console'
  gem 'listen'
  gem 'rubocop', require: false
  gem 'spring'
  gem 'spring-watcher-listen'
end

group :production do
  gem 'skylight'
  gem 'lograge'
  gem 'puma_worker_killer'
end
