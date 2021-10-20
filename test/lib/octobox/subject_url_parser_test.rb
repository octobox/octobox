require 'test_helper'

class SubjectUrlParserTest < ActiveSupport::TestCase
  test "to_html_url correctly converts an API issue to an HTML one" do
    url = "https://api.github.com/repos/octokit/octokit.rb/issues/123"
    without_comment = Octobox::SubjectUrlParser.new(url)
    with_comment    = Octobox::SubjectUrlParser.new(url, latest_comment_url: "https://api.github.com/repos/octokit/octokit.rb/comments/1")

    assert_equal "https://github.com/octokit/octokit.rb/issues/123", without_comment.to_html_url
    assert_equal "https://github.com/octokit/octokit.rb/issues/123#issuecomment-1", with_comment.to_html_url
  end

  test "to_html_url correctly coverts an API commit URL to an HTML one" do
    url = "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e"
    without_comment = Octobox::SubjectUrlParser.new(url)
    with_comment    = Octobox::SubjectUrlParser.new(url, latest_comment_url: "https://api.github.com/repos/octocat/Hello-World/pulls/comments/1")

    assert_equal "https://github.com/octocat/Hello-World/commit/6dcb09b5b57875f334f61aebed695e2e4193db5e", without_comment.to_html_url
    assert_equal "https://github.com/octocat/Hello-World/commit/6dcb09b5b57875f334f61aebed695e2e4193db5e#commitcomment-1", with_comment.to_html_url
  end

  test "to_html_url correctly identifies and doesn't convert an already HTML url" do
    url = "https://github.com/octokit/octokit.rb/issues/123"
    without_comment = Octobox::SubjectUrlParser.new(url)
    with_comment    = Octobox::SubjectUrlParser.new(url, latest_comment_url: "https://api.github.com/repos/octokit/octokit.rb/comments/1")

    assert_equal "https://github.com/octokit/octokit.rb/issues/123", without_comment.to_html_url
    assert_equal "https://github.com/octokit/octokit.rb/issues/123#issuecomment-1", with_comment.to_html_url
  end

  test "to_api_url correctly coverts an HTML commit URL to an api one" do
    url = "https://github.com/octocat/Hello-World/issues/123"
    parsed_url = Octobox::SubjectUrlParser.new(url)

    assert_equal "https://api.github.com/repos/octocat/Hello-World/issues/123", parsed_url.to_api_url
  end

  test "to_api_url correctly identifies and doesn't convert an already api url" do
    url = "https://api.github.com/repos/octocat/Hello-World/issues/123"
    parsed_url = Octobox::SubjectUrlParser.new(url)

    assert_equal "https://api.github.com/repos/octocat/Hello-World/issues/123", parsed_url.to_api_url
  end

  test "it correctly identifies an API pull request URL" do
    parser = Octobox::SubjectUrlParser.new("https://api.github.com/repos/octocat/Hello-World/pulls/1347")
    assert parser.api_url?
    assert_pull_request_url parser
  end

  test "it correctly identifies a HTML pull request URL" do
    parser = Octobox::SubjectUrlParser.new("https://github.com/octocat/Hello-World/pull/1347")
    assert parser.html_url?
    assert_pull_request_url parser
  end

  test "it correctly identifies an API issue URL" do
    parser = Octobox::SubjectUrlParser.new("https://api.github.com/repos/octocat/Hello-World/issues/1347")
    assert parser.api_url?
    assert_issue_url parser
  end

  test "it correctly identifies a HTML issue URL" do
    parser = Octobox::SubjectUrlParser.new("https://github.com/octocat/Hello-World/issues/1347")
    assert parser.html_url?
    assert_issue_url parser
  end

  test "it correctly identifies an API commit URL" do
    parser = Octobox::SubjectUrlParser.new("https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e")
    assert parser.api_url?
    assert_commit_url parser
  end

  test "it correctly identifies a HTML commit URL" do
    parser = Octobox::SubjectUrlParser.new("https://github.com/octocat/Hello-World/commit/6dcb09b5b57875f334f61aebed695e2e4193db5e")
    assert parser.html_url?
    assert_commit_url parser
  end

  test "it correctly identifies an API release URL" do
    parser = Octobox::SubjectUrlParser.new("https://api.github.com/repos/octocat/Hello-World/releases/1")
    assert parser.api_url?
    assert_release_url parser
  end

  test "it correctly identifies a HTML release URL" do
    parser = Octobox::SubjectUrlParser.new("https://github.com/octocat/Hello-World/releases/v1.0.0")
    assert parser.html_url?
    assert_release_url parser
  end

  def assert_pull_request_url(parser)
    assert parser.pull_request?
    refute parser.issue?
    refute parser.commit?
    refute parser.release?
  end

  def assert_issue_url(parser)
    refute parser.pull_request?
    assert parser.issue?
    refute parser.commit?
    refute parser.release?
  end

  def assert_commit_url(parser)
    refute parser.pull_request?
    refute parser.issue?
    assert parser.commit?
    refute parser.release?
  end

  def assert_release_url(parser)
    refute parser.pull_request?
    refute parser.issue?
    refute parser.commit?
    assert parser.release?
  end
end

