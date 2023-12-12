source 'https://rubygems.org'
ruby '3.2.2'

gem 'rails', '7.1.2'
gem 'bootstrap', '4.6.2'
gem 'attr_encrypted', git: 'https://github.com/octobox/attr_encrypted.git', branch: 'rails-7'
gem 'jquery-rails'
gem 'rails-ujs'
gem 'pagy'
gem 'local_time'
gem 'octicons_helper'
gem 'octokit'
gem 'omniauth-github', '2.0.1'
gem 'puma'
gem 'sassc-rails'
gem 'turbolinks'
gem 'typhoeus'
gem 'faraday_middleware'
gem 'faraday'
gem 'uglifier'
gem 'pg_search'
gem 'jbuilder'
gem 'rake', require: false
gem 'rgb'
gem 'sidekiq'
gem 'sidekiq-unique-jobs', git: 'https://github.com/mhenrixon/sidekiq-unique-jobs', ref: 'b31e80b'
gem 'sidekiq-scheduler', require: false
gem 'rack-canonical-host'
gem 'sidekiq-status'
gem 'gemoji', '<4', require: false
gem 'bootsnap', require: false
gem 'bugsnag'
gem 'jwt'
gem 'oj'
gem 'yard', require: false
gem 'commonmarker'
gem 'pg'
gem 'rexml'
gem 'omniauth-rails_csrf_protection'
gem 'psych'
gem 'nokogiri'

group :development, :test do
  gem 'dotenv-rails'
  gem 'rails-controller-testing'
  gem 'sql_queries_count'
  gem 'active_record_query_trace'
end

group :test do
  gem 'factory_bot'
  gem 'webmock'
  gem 'mocha'
  gem 'minitest'
  gem 'timecop'
end

group :development do
  gem 'web-console'
  gem 'listen'
  gem 'spring'
  gem 'brakeman'
  gem 'binding_of_caller'
  gem 'better_errors'
end

group :production do
  gem 'skylight', '~> 6.0.1'
  gem 'lograge'
  gem 'puma_worker_killer'
end
