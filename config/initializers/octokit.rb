# frozen_string_literal: true
require 'typhoeus/adapters/faraday'

Octokit.middleware = Faraday::RackBuilder.new do |builder|
  builder.use :http_cache, store: Rails.cache, logger: Rails.logger, shared_cache: false, serializer: Marshal
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError
  builder.use Octokit::Response::FeedParser
  builder.use FaradayMiddleware::Gzip
  builder.request :retry
  builder.adapter :typhoeus
end

Octokit.configure do |c|
  c.api_endpoint = Octobox.github_api_prefix
  c.web_endpoint = Octobox.github_domain
end
