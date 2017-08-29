module Octobox
  class SubjectUrlParser
    attr_reader :url

    def initialize(url, latest_comment_url: nil)
      @url = url
      @latest_comment_url = latest_comment_url
    end

    # NOTE Releases are defaulted to the release index page
    def to_web_url
      web_url = url.gsub("#{Octobox.config.github_api_prefix}/repos", Octobox.config.github_domain)
        .gsub('/pulls/', '/pull/')
        .gsub('/commits/', '/commit/')
        .gsub(/\/releases\/\d+/, '/releases/')

      if @latest_comment_url.present?
        if pull_request? || issue? then web_url << "#issuecomment-#{comment_id}"
        elsif commit? then web_url << "#commitcomment-#{comment_id}"
        end
      end

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
  end
end
