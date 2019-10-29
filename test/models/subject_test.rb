# frozen_string_literal: true
require 'test_helper'

class SubjectTest < ActiveSupport::TestCase

  setup do
    stub_include_comments
  end

  test 'update_labels creates a label when a matching one does not exist' do
    subject = create(:subject)
    labels = [load_fixture("label.json")["label"]]
    assert 0, subject.labels.count

    subject.update_labels labels

    label = subject.labels.first
    assert_equal true, label.present?
    assert_equal 1023072455, label.github_id
    assert_equal "080bcc", label.color
    assert_equal ":carrot: :carrot:", label.name
    assert_equal 1, subject.labels.count
  end

  test 'update_labels updates labels' do
    subject = create(:subject)
    create(:label, subject: subject, github_id: "1023072455")
    labels = [load_fixture("label.json")["label"]]
    assert_equal 1, subject.labels.count

    subject.update_labels labels

    label = subject.labels.first.reload
    assert_equal true, label.present?
    assert_equal 1023072455, label.github_id
    assert_equal "080bcc", label.color
    assert_equal ":carrot: :carrot:", label.name
    assert_equal 1, subject.labels.count
  end

  test 'update_labels destroys labels that no longer exist' do
    subject = create(:subject)
    label = create(:label, subject: subject)
    labels = [load_fixture("label.json")["label"]]

    assert true, label.persisted?

    subject.update_labels labels

    assert true, label.destroyed?
  end

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
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal 8, subject.comment_count
  end

  test 'sync updates comment_count of a pull request' do
    stub_comments_requests

    remote_subject = load_fixture('merged_pull_request.json')

    user = create(:user)
    create(:notification, subject_url:remote_subject['url'], user: user)
    subject = create(:subject, url: remote_subject['url'])
    subject.sync(remote_subject)
    assert_equal 0, subject.comment_count
  end

  test 'sync updates comment_count of a commit' do
    remote_subject = load_fixture('commit_no_author.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal 2, subject.comment_count
  end

  test 'sync updates body of an issue' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert subject.body.present?
  end

  test "sync doesn't update comment_count of releases" do
    remote_subject = load_fixture('release.json')
    subject = create(:subject, comment_count: nil)
    subject.sync(remote_subject)
    assert_nil subject.comment_count
  end

  test 'sync updates a matching subject' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject, url: remote_subject['url'], comment_count: nil)
    subject.sync(remote_subject)
    assert_equal 8, subject.comment_count
  end

  test "sync creates a new subject when a matching one can't be found" do
    assert_equal 0, Subject.count
    remote_subject = load_fixture('subject_56.json')
    Subject.sync(remote_subject)
    assert_equal 1, Subject.count
  end

  test 'sync sets the full name when there is repository info' do
    remote_subject = load_fixture('subject_56.json')
    remote_subject['repository'] = {'full_name' => 'repository full name'}
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal 'repository full name', Subject.last.repository_full_name
  end

  test 'sync sets the full name when there is no repository info' do
    remote_subject = load_fixture('subject_56.json')
    assert_nil remote_subject['repository']
    remote_subject['repository'] = {'full_name' => 'repository full name'}
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal 'repository full name', subject.repository_full_name
  end

  test 'sync sets the github_id' do
    remote_subject = load_fixture('subject_56.json')
    expected_github_id = 5
    remote_subject['id'] = expected_github_id
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal expected_github_id, subject.github_id
  end

  test 'sync sets the state when the subject is merged' do
    stub_comments_requests

    remote_subject = load_fixture('merged_pull_request.json')

    user = create(:user)
    create(:notification, subject_url:remote_subject['url'], user: user)
    subject = create(:subject, url: remote_subject['url'])

    refute_empty remote_subject['merged_at']
    subject.sync(remote_subject)
    assert_equal 'merged', subject.state
  end

  test 'sync sets the state' do
    remote_subject = load_fixture('subject_56.json')
    assert_nil remote_subject['merged_at']
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal 'closed', subject.state
  end

  test 'sync sets the author' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal 'andrew', subject.author
  end

  test "sync sets the author to nil when it's not present" do
    remote_subject = load_fixture('commit_no_author.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_nil subject.author
  end

  test 'sync sets the html_url' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal 'https://github.com/octobox/octobox/issues/56', subject.html_url
  end

  test 'sync sets the created_at value' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal DateTime.parse('2016-12-19T21:30:41Z'), subject.created_at
  end

  test "sync sets a default created_at value when it's not present" do
    created_at = DateTime.parse('2019-01-01 09:00:00')
    travel_to created_at
    remote_subject = load_fixture('commit_no_author.json')
    assert_nil remote_subject['created_at']
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal created_at, subject.created_at
  end

  test 'sync sets the updated_at value' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal DateTime.parse('2016-12-27T20:10:18Z'), subject.updated_at
  end

  test "sync sets a default updated_at value when it's not present" do
    updated_at = DateTime.parse('2019-01-01 09:00:00')
    travel_to updated_at
    remote_subject = load_fixture('commit_no_author.json')
    assert_nil remote_subject['updated_at']
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal updated_at, subject.updated_at
  end

  test 'sync sets the comment_count' do
    remote_subject = load_fixture('subject_56.json')
    refute_nil(remote_subject['comments'])
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal 8, subject.comment_count
  end

  test 'sync sets the comment_count for commits' do
    remote_subject = load_fixture('commit_no_author.json')
    assert_nil(remote_subject['comments'])
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal 2, subject.comment_count
  end

  test 'sync sets the assignees' do
    remote_subject = load_fixture('subject_57.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal ':andrew:', subject.assignees
  end

  test 'sync sets an empty assignees value when there are non present' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal '::', subject.assignees
  end

  test 'sync sets the locked value' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal false, subject.locked
  end

  test 'sync sets the sha' do
    stub_comments_requests

    remote_subject = load_fixture('merged_pull_request.json')

    user = create(:user)
    create(:notification, subject_url: remote_subject['url'], user: user)
    create(:subject, url: remote_subject['url'])

    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal '84b4e75e5f627d34f7a85982bda7b260f34db4dd', subject.sha
  end

  test "sync sets the sha to nil when it's not present" do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    assert_nil subject.sha
  end

  test 'sync sets the body' do
    stub_comments_requests

    remote_subject = load_fixture('merged_pull_request.json')
    remote_subject['body'] << "\u0000" # create null terminated string

    user = create(:user)
    create(:notification, subject_url:remote_subject['url'], user: user)
    create(:subject, url: remote_subject['url'])

    subject = create(:subject)
    subject.sync(remote_subject)
    assert_equal 'Fixed this thing', subject.body
  end

  test 'sync updates labels when the subjects is persisted and labels are present in the remote subject' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.expects(:update_labels)
    subject.sync(remote_subject)
  end

  test 'sync does not update labels when the subject is not persisted' do
    remote_subject = load_fixture('subject_56.json')
    subject = build(:subject)
    subject.expects(:valid?).at_least_once.returns(false)
    subject.expects(:update_labels).never
    subject.sync(remote_subject)
    assert_equal 0, Subject.count
  end

  test 'sync updates the comments when the subject is persisted and comments are available' do
    remote_subject = load_fixture('subject_56.json')
    subject = build(:subject)
    Octobox.expects(:include_comments?).returns(true)
    subject.expects(:update_comments)
    subject.sync(remote_subject)
    assert subject.persisted?
  end

  test 'sync updates reviews and review comemnts when the subject is a pull request' do
    remote_subject = load_fixture('subject_58.json')
    stub_review_requests

    user = create(:user)
    create(:notification, subject_url:remote_subject['url'], user: user)
    subject = create(:subject, url: remote_subject['url'])

    subject.sync(remote_subject)

    assert_equal 24, subject.comments.count
  end

  test 'review states are saved is there is a review with a state' do
    remote_subject = load_fixture('subject_58.json')
    stub_review_requests

    user = create(:user)
    create(:notification, subject_url:remote_subject['url'], user: user)
    create(:subject, url: remote_subject['url'])

    Subject.sync_comments(remote_subject)    

    assert_equal 1, Comment.where(review_state: "CHANGES_REQUESTED").count

  end

  test 'sync does not update comments when subject is not persisted' do
    remote_subject = load_fixture('subject_56.json')
    subject = build(:subject)
    subject.expects(:valid?).at_least_once.returns(false)
    subject.expects(:update_comments).never
    subject.sync(remote_subject)
    assert_equal 0, Subject.count
  end

  test 'sync does not update comments when comments are disabled' do
    remote_subject = load_fixture('subject_56.json')
    Octobox.expects(:include_comments?).at_least_once.returns(false)
    subject = create(:subject)
    subject.expects(:update_comments).never
    subject.sync(remote_subject)
  end

  test 'sync does not update comments when the subejct has no comments' do
    remote_subject = load_fixture('release.json')
    subject = create(:subject)
    Octobox.expects(:include_comments?).at_least_once.returns(true)
    subject.expects(:update_comments).never
    subject.sync(remote_subject)
  end

  test 'sync updates the status when the subject is persisted' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.expects(:update_status)
    subject.sync(remote_subject)
  end

  test 'sync does not update the status when the subject is not persisted' do
    remote_subject = load_fixture('subject_56.json')
    subject = build(:subject)
    subject.expects(:valid?).at_least_once.returns(false)
    subject.expects(:update_status).never
    subject.sync(remote_subject)
    refute subject.persisted?
  end

  test 'sync updates involved users when the subject is persisted and there are notifiable fields that have changed' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.expects(:sync_involved_users)
    subject.sync(remote_subject)
  end

  test 'sync does not update involved users when the subject is not persisted' do
    remote_subject = load_fixture('subject_56.json')
    subject = build(:subject)
    subject.expects(:valid?).at_least_once.returns(false)
    subject.expects(:sync_involved_users).never
    subject.sync(remote_subject)
    assert_equal 0, Subject.count
  end

  test 'sync does not update involved users when there are no saved changes' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.sync(remote_subject)
    subject.expects(:sync_involved_users).never
    subject.sync(remote_subject)
  end

  test 'sync does not update involved users when there are no notifiable fields' do
    remote_subject = load_fixture('subject_56.json')
    subject = create(:subject)
    subject.expects(:notifiable_fields).returns([])
    subject.expects(:sync_involved_users).never
    subject.sync(remote_subject)
  end

  def load_fixture(filename)
    Oj.load(file_fixture(filename).read)
  end
end
