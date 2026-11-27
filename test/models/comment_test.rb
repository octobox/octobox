# frozen_string_literal: true
require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'web_url links to the comment on the subject page' do
    subject = create(:subject, html_url: 'https://github.com/octobox/octobox/issues/56')
    comment = create(:comment, subject: subject, github_id: 123)

    assert_equal 'https://github.com/octobox/octobox/issues/56#issuecomment-123', comment.web_url
  end

  test 'author_url_path links to the profile of a user' do
    assert_equal '/benjam', build(:comment, author: 'benjam').author_url_path
  end

  test 'author_url_path links to the app page of a bot' do
    comment = build(:comment, author: 'dependabot[bot]')

    assert comment.bot_author?
    assert_equal '/apps/dependabot', comment.author_url_path
  end
end
