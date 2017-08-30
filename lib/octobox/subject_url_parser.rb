module Octobox
  class SubjectUrlParser
    attr_reader :url,
                :github_api_prefix,
                :github_domain

    delegate :config, to: Octobox

    def initialize(url, github_api_prefix: config.github_api_prefix, github_domain: config.github_domain, latest_comment_url: nil)
      @url = url
      @github_api_prefix = github_api_prefix
      @github_domain = github_domain
      @latest_comment_url = latest_comment_url
    end

    # NOTE Releases are defaulted to the release index page
    def to_web_url
      web_url = url.gsub("#{github_api_prefix}/repos", github_domain)
        .gsub('/pulls/', '/pull/')
        .gsub('/commits/', '/commit/')
        .gsub(/\/releases\/\d+/, '/releases/')
      web_url << latest_comment_anchor

      web_url
    end

    def pull_request?
      /\/pull(?:s)?\// =~ url
    end

    def issue?
      /\/issues\// =~ url
    end

    def commit?
      /\/commit(?:s)?\// =~ url
    end

    def release?
      /\/releases\// =~ url
    end

    private

    def comment_id
      return @comment_id if defined?(@comment_id)
      match = /comments\/(?<comment_id>\d+)\z/.match(@latest_comment_url)
      @comment_id = match[:comment_id] if match.present?
    end

    def latest_comment_anchor
      return "" unless comment_id.present?

      if pull_request? || issue? then "#issuecomment-#{comment_id}"
      elsif commit? then "#commitcomment-#{comment_id}"
      end
    end
  end
end
