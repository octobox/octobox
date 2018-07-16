class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_github_request!

  def create
    p params
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
