# frozen_string_literal: true
require 'test_helper'

class SubjectTest < ActiveSupport::TestCase
  test 'sync_status updates the status of subject' do
    sha = 'a10867b14bb761a232cd80139fbd4c0d33264240'
    user = create(:user)
    notification = create(:notification, user: user)
    subject = create(:subject, url: notification.subject_url, status: "pending", sha: sha)

    url = "https://api.github.com/repos/octobox/octobox/commits/#{sha}/status"
    response = { status: 200, body: file_fixture('status_success.json'), headers: { 'Content-Type' => 'application/json' } }
    stub_request(:get, url).and_return(response)

    Subject.sync_status(sha, 'octobox/octobox')

    subject.reload

    assert_equal 'success', subject.status
  end

  test 'sync updates comment_count of an issue' do
    remote_subject = Oj.load(File.open(file_fixture('subject_56.json')))
    Subject.sync(remote_subject)
    subject = Subject.first
    assert_equal 8, subject.comment_count
  end

  test 'sync updates comment_count of a pull request' do
    remote_subject = Oj.load(File.open(file_fixture('merged_pull_request.json')))
    Subject.sync(remote_subject)
    subject = Subject.first
    assert_equal 0, subject.comment_count
  end

  test 'sync updates comment_count of a commit' do
    remote_subject = Oj.load(File.open(file_fixture('commit_no_author.json')))
    Subject.sync(remote_subject)
    subject = Subject.first
    assert_equal 2, subject.comment_count
  end

  test 'sync updates body of an issue' do
    remote_subject = Oj.load(File.open(file_fixture('subject_56.json')))
    Subject.sync(remote_subject)
    subject = Subject.first
    assert subject.body.present?
  end

  test "sync doesn't update comment_count of releases" do
    remote_subject = Oj.load(File.open(file_fixture('release.json')))
    Subject.sync(remote_subject)
    subject = Subject.first
    assert_nil subject.comment_count
  end

  test 'sync updates a matching subject' do
    remote_subject = Oj.load(File.open(file_fixture('subject_56.json')))
    subject = create(:subject, url: remote_subject['url'], comment_count: nil)
    Subject.expects(:find_or_create_by).returns(subject)
    Subject.sync(remote_subject)
    assert_equal 8, subject.comment_count
  end

  test "sync creates a new subject when a matching one can't be found" do
    assert_equal 0, Subject.count
    remote_subject = Oj.load(File.open(file_fixture('subject_56.json')))
    Subject.sync(remote_subject)
    assert_equal 1, Subject.count
  end

  test 'sync sets the full name when there is repository info' do
    remote_subject = Oj.load(File.open(file_fixture('subject_56.json')))
    remote_subject['repository'] = {'full_name' => 'repository full name'}
    Subject.sync(remote_subject)
    assert_equal 'repository full name', Subject.last.repository_full_name
  end

  test 'sync sets the full name when there is no repository info' do
    remote_subject = Oj.load(File.open(file_fixture('subject_56.json')))
    assert_nil remote_subject['repository']
    remote_subject['repository'] = {'full_name' => 'repository full name'}
    Subject.sync(remote_subject)
    assert_equal 'repository full name', Subject.last.repository_full_name
  end
end
