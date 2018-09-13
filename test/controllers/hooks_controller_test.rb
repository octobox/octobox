# frozen_string_literal: true
require 'test_helper'

class HooksControllerTest < ActionController::TestCase
  test 'labels webhook payload' do
    send_webhook 'label'
  end

  test 'github_app_authorization webhook payload' do
    send_webhook 'github_app_authorization'
  end

  test 'installation_repositories webhook payload' do
    send_webhook 'installation_repositories'
  end

  test 'installation webhook payload' do
    send_webhook 'installation'
  end

  test 'issues webhook payload' do
    send_webhook 'issues'
  end

  test 'pull_request webhook payload' do
    send_webhook 'pull_request'
  end

  test 'issue_comment webhook payload' do
    send_webhook 'issue_comment'
  end
end

def send_webhook(event_type)
  @request.headers['X-GitHub-Event'] = event_type
  post :create, body: File.read("#{Rails.root}/test/fixtures/github_webhooks/#{event_type}.json")
  assert_response :success
end
