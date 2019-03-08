# frozen_string_literal: true
require 'test_helper'

class HooksControllerTest < ActionController::TestCase
  test 'labels webhook payload' do
    repository = create(:repository, github_id: 139431141)
    notification = create(:notification, repository_full_name: repository.full_name)
    subject = create(:subject, repository: repository, url: notification.subject_url)
    label = create(:label, subject: subject, name: ':carrot:')
    Notification.any_instance.expects(:update_subject)
    send_webhook 'label'
  end

  test 'github_app_authorization webhook payload' do
    user = create(:user, app_token: 'abcdefg', github_id: 1060)
    send_webhook 'github_app_authorization'
    user.reload
    assert_nil user.app_token
  end

  test 'installation_repositories webhook payload' do
    stub_access_tokens_request
    app = create(:app_installation, github_id: 293804)
    send_webhook 'installation_repositories'
    assert_equal Repository.count, 1
  end

  test 'installation webhook payload' do
    stub_access_tokens_request
    send_webhook 'installation'
    assert_equal AppInstallation.count, 1
  end

  test 'installation new_permissions_accepted webhook payload' do
    stub_access_tokens_request
    app = create(:app_installation, github_id: 293804, permission_pull_requests: 'read')
    response = { status: 200, body: file_fixture('app_installation.json'), headers: { 'Content-Type' => 'application/json' } }
    stub_request(:get, "https://api.github.com/app/installations/293804").and_return(response)
    send_webhook 'installation', 'installation_update'
    app.reload
    assert_equal app.permission_pull_requests, "write"
  end

  test 'issues webhook payload' do
    send_webhook 'issues'
    assert_equal Subject.count, 1
  end

  test 'pull_request webhook payload' do
    send_webhook 'pull_request'
    assert_equal Subject.count, 1
  end

  test 'pull_request_review webhook payload' do
    send_webhook 'pull_request_review'
    assert_equal Subject.count, 1
  end

  test 'pull_request_review_comment webhook payload' do
    send_webhook 'pull_request_review_comment'
    assert_equal Subject.count, 1
  end

  test 'issue_comment webhook payload' do
    send_webhook 'issue_comment'
    assert_equal Subject.count, 1
  end

  test 'status webhook payload' do
    stub_notifications_request
    stub_repository_request
    user = create(:user)
    notification = create(:notification, user: user)
    subject = create(:subject, repository_full_name: 'Codertocat/Hello-World',
                               sha: 'a10867b14bb761a232cd80139fbd4c0d33264240',
                               url: notification.subject_url)

    statuses_url = "https://api.github.com/repos/Codertocat/Hello-World/commits/a10867b14bb761a232cd80139fbd4c0d33264240/status"
    response = { status: 200, body: file_fixture('status_request.json'), headers: { 'Content-Type' => 'application/json' } }
    stub_request(:get, statuses_url).and_return(response)

    send_webhook 'status'
    subject.reload
    assert_equal subject.status, 'failure'
  end

  test 'repository webhook payload' do
    send_webhook 'repository'
    assert_equal Repository.count, 1
  end
end

def send_webhook(event_type, fixture = nil)
  fixture = event_type if fixture.nil?
  @request.headers['X-GitHub-Event'] = event_type
  Sidekiq::Testing.inline! do
    inline_sidekiq_status do
      post :create, body: File.read("#{Rails.root}/test/fixtures/github_webhooks/#{fixture}.json")
    end
  end
  assert_response :success
end
