source 'https://rubygems.org'
ruby '2.5.0'

gem 'rails', '~> 5.1', '>= 5.1.3'
gem 'bootstrap-sass'
gem 'jquery-rails'
gem 'kaminari'
gem 'local_time', git: 'https://github.com/twalpole/local_time', branch: 'turbolinks5'
gem 'octicons_helper'
gem 'octokit', '~> 4.7'
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

# Supported databases
gem 'mysql2', require: false
gem 'pg', '~> 0.18', require: false

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
  gem 'rails_safe_tasks'
  gem 'bugsnag'
  gem 'puma_worker_killer'
  gem "rack-timeout"
end
