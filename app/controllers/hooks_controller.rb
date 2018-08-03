class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  before_action :authenticate_github_request!

  def create
    case event_header
    when 'issues'
      remote_subject = JSON.parse(params['issue'].to_json, object_class: OpenStruct)
      subject = Subject.find_or_create_by(url: remote_subject.url)
      subject.update({
        state: remote_subject.state,
        author: remote_subject.user.login,
        html_url: remote_subject.html_url,
        created_at: remote_subject.created_at,
        updated_at: remote_subject.updated_at
      })
      subject.sync_involved_users
    when 'pull_request'
      remote_subject = JSON.parse(params['pull_request'].to_json, object_class: OpenStruct)
      subject = Subject.find_or_create_by(url: remote_subject.url)
      subject.update({
        state: remote_subject.merged_at.present? ? 'merged' : remote_subject.state,
        author: remote_subject.user.login,
        html_url: remote_subject.html_url,
        created_at: remote_subject.created_at,
        updated_at: remote_subject.updated_at
      })
      subject.sync_involved_users
    when 'issue_comment'
      # TODO sync comments once thread-view branch merged
      # https://developer.github.com/v3/activity/events/types/#issuecommentevent
    when 'pull_request_review'
      # TODO check to see if this gets fired other than when 'pull_request' is fired
      # https://developer.github.com/v3/activity/events/types/#pullrequestreviewevent
    when 'pull_request_review_comment'
      # TODO check to see if this gets fired other than when 'pull_request' is fired
      # https://developer.github.com/v3/activity/events/types/#pullrequestreviewcommentevent
    when 'label'
      # TODO find and update labels on subjects for the repo
      # https://developer.github.com/v3/activity/events/types/#labelevent
    when 'installation'
      # TODO record/update github app installation
      # https://developer.github.com/v3/activity/events/types/#installationevent
    when 'installation_repositories'
      # TODO add/remove repositories from an installation
      # https://developer.github.com/v3/activity/events/types/#installationrepositoriesevent
    when 'marketplace_purchase'
      # TODO purchase, upgrade/downgrade or cancel marketplace plan
      # https://developer.github.com/apps/marketplace/setting-up-github-marketplace-webhooks/about-webhook-payloads-for-a-github-marketplace-listing/
    end

    head :no_content
  end

  private

  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  def authenticate_github_request!
    secret = Rails.application.secrets.github_webhook_secret

    expected_signature = "sha1=#{OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, request_body)}"
    if signature_header != expected_signature
      raise SignatureError
    end
  end

  def request_body
    @request_body ||= (
      request.body.rewind
      request.body.read
    )
  end

  def signature_header
    request.headers['X-Hub-Signature']
  end

  def event_header
    request.headers['X-GitHub-Event']
  end
end
