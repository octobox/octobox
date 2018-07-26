class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  before_action :authenticate_github_request!

  def create
    p params
    p event_header

    if event_header == 'issues'
      remote_subject = JSON.parse(params['issue'].to_json, object_class: OpenStruct)
      subject = Subject.find_or_create_by(html_url: remote_subject.html_url)
      subject.update({
        state: remote_subject.state,
        author: remote_subject.user.login,
        html_url: remote_subject.html_url,
        created_at: remote_subject.created_at,
        updated_at: remote_subject.updated_at
      })
    end

    if event_header == 'pull_request'
      remote_subject = JSON.parse(params['pull_request'].to_json, object_class: OpenStruct)
      subject = Subject.find_or_create_by(html_url: remote_subject.html_url)
      subject.update({
        state: remote_subject.merged_at.present? ? 'merged' : remote_subject.state,
        author: remote_subject.user.login,
        html_url: remote_subject.html_url,
        created_at: remote_subject.created_at,
        updated_at: remote_subject.updated_at
      })
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
