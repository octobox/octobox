# frozen_string_literal: true
require Rails.root.join('lib/octobox')
require 'typhoeus/adapters/faraday'

Octokit.configure do |c|
  c.api_endpoint = Octobox.config.github_api_prefix
  c.web_endpoint = Octobox.config.github_domain
end

Octokit.middleware = Faraday::RackBuilder.new do |builder|
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError
  builder.use FaradayMiddleware::Gzip
  builder.use :instrumentation
  builder.request :retry
  builder.adapter :typhoeus
end
