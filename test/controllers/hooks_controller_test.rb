# frozen_string_literal: true
require 'test_helper'

class HooksControllerTest < ActionController::TestCase
  test 'labels webhook payload' do
    @request.headers['X-GitHub-Event'] = 'label'
    fixture = 'label.json'
    post :create, body: File.read("#{Rails.root}/test/fixtures/github_webhooks/#{fixture}")
    assert_response :success
  end

  test 'github_app_authorization webhook payload' do
    @request.headers['X-GitHub-Event'] = 'github_app_authorization'
    fixture = 'github_app_authorization.json'
    post :create, body: File.read("#{Rails.root}/test/fixtures/github_webhooks/#{fixture}")
    assert_response :success
  end

  test 'installation_repositories webhook payload' do
    @request.headers['X-GitHub-Event'] = 'installation_repositories'
    fixture = 'installation_repositories.json'
    post :create, body: File.read("#{Rails.root}/test/fixtures/github_webhooks/#{fixture}")
    assert_response :success
  end

  test 'installation webhook payload' do
    @request.headers['X-GitHub-Event'] = 'installation'
    fixture = 'installation.json'
    post :create, body: File.read("#{Rails.root}/test/fixtures/github_webhooks/#{fixture}")
    assert_response :success
  end

  test 'issues webhook payload' do
    @request.headers['X-GitHub-Event'] = 'issues'
    fixture = 'issues.json'
    post :create, body: File.read("#{Rails.root}/test/fixtures/github_webhooks/#{fixture}")
    assert_response :success
  end

  test 'pull_request webhook payload' do
    @request.headers['X-GitHub-Event'] = 'pull_request'
    fixture = 'pull_request.json'
    post :create, body: File.read("#{Rails.root}/test/fixtures/github_webhooks/#{fixture}")
    assert_response :success
  end

  test 'issue_comment webhook payload' do
    @request.headers['X-GitHub-Event'] = 'issue_comment'
    fixture = 'issue_comment.json'
    post :create, body: File.read("#{Rails.root}/test/fixtures/github_webhooks/#{fixture}")
    assert_response :success
  end
end
