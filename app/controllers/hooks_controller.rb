class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  before_action :authenticate_github_request!

  def create
    case event_header
    when 'issues', 'issue_comment'
      remote_subject = payload.issue
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
      remote_subject = payload.pull_request
      subject = Subject.find_or_create_by(url: remote_subject.url)
      subject.update({
        state: remote_subject.merged_at.present? ? 'merged' : remote_subject.state,
        author: remote_subject.user.login,
        html_url: remote_subject.html_url,
        created_at: remote_subject.created_at,
        updated_at: remote_subject.updated_at
      })
      subject.sync_involved_users
    when 'label'
      if payload.action == 'edited'
        repository = Repository.find_by_github_id(payload.repository.id)
        return if repository.nil?
        subjects = repository.subjects.label(payload.changes.name.from)
        subjects.each do |subject|
          n = subject.notifications.first
          n.try(:send, :update_subject, true)
        end
      end
    when 'installation'
      case payload.action
      when 'created'
        app_installation = AppInstallation.create({
          github_id: payload.installation.id,
          app_id: payload.installation.app_id,
          account_login: payload.installation.account.login,
          account_id: payload.installation.account.id,
          account_type: payload.installation.account.type,
          target_type: payload.installation.target_type,
          target_id: payload.installation.target_id,
          permission_pull_requests: payload.installation.permissions.pull_requests,
          permission_issues: payload.installation.permissions.issues
        })

        payload.repositories.each do |remote_repository|
          repository = Repository.find_or_create_by(github_id: remote_repository.id)

          repository.update_attributes({
            full_name: remote_repository.full_name,
            private: remote_repository.private,
            owner: remote_repository.full_name.split('/').first,
            github_id: remote_repository.id,
            last_synced_at: Time.current,
            app_installation_id: app_installation.id
          })

          repository.notifications.each{|n| n.send :update_subject, true }
        end
      when 'deleted'
        AppInstallation.find_by_github_id(payload.installation.id).try(:destroy)
      end

    when 'installation_repositories'
      app_installation = AppInstallation.find_by_github_id(payload.installation.id)
      return unless app_installation.present?
      payload.repositories_added.each do |remote_repository|
        repository = app_installation.repositories.find_or_create_by(github_id: remote_repository.id)

        repository.update_attributes({
          full_name: remote_repository.full_name,
          private: remote_repository.private,
          owner: remote_repository.full_name.split('/').first,
          github_id: remote_repository.id,
          last_synced_at: Time.current,
          app_installation_id: app_installation.id
        })

        repository.notifications.each{|n| n.send :update_subject, true }
      end

      payload.repositories_removed.each do |remote_repository|
        repository = app_installation.repositories.find_by_github_id(remote_repository.id)
        next unless repository.present?
        repository.subjects.each(&:destroy)
        repository.destroy
      end
    when 'github_app_authorization'
      user = User.find_by_github_id(payload.sender.id)
      user.update_attributes(app_token: nil) if user.present?
    end

    head :no_content
  end

  private

  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  def authenticate_github_request!
    secret = Rails.application.secrets.github_webhook_secret

    return unless secret.present?

    expected_signature = "sha1=#{OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, request_body)}"
    if signature_header != expected_signature
      raise ActiveSupport::MessageVerifier::InvalidSignature
    end
  end

  def request_body
    @request_body ||= (
      request.body.rewind
      request.body.read
    )
  end

  def payload
    @payload ||= JSON.parse(request_body, object_class: OpenStruct)
  end

  def signature_header
    request.headers['X-Hub-Signature']
  end

  def event_header
    request.headers['X-GitHub-Event']
  end
end
