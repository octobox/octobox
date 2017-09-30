# frozen_string_literal: true
require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  test 'author_url returns a user url with users' do
    subject = create(:subject, author: "Fryguy")
    assert_equal "https://github.com/Fryguy", subject.author_url
  end

  test 'author_url returns a GitHub apps URL with bots' do
    subject = create(:subject, author: "greenkeeper[bot]")
    assert_equal "https://github.com/apps/greenkeeper", subject.author_url
  end
end
