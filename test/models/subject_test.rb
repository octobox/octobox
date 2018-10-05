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

  test 'sync_status updates the status of subject' do
    subject = create(:subject, status: "pending", sha: 'a10867b14bb761a232cd80139fbd4c0d33264240')
  	Subject.sync_status('a10867b14bb761a232cd80139fbd4c0d33264240', 'success')

    subject.reload

    assert_equal 'success', subject.status
  end

end
