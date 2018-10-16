# frozen_string_literal: true
class PersonalAccessTokenValidator < ActiveModel::Validator

  ERRORS = {
    invalid_token: [:personal_access_token, 'is not a valid token for this github user'],
    missing_notifications_scope: [:personal_access_token, 'does not include the notifications scope'],
    missing_read_org_scope: [:personal_access_token, 'does not include the read:org scope'],
    disallowed_tokens: [:personal_access_token, 'is not allowed in this instance'],
  }.freeze

  def validate(record)
    return if record.personal_access_token.blank?
    validate_tokens_are_enabled(record)
    validate_token_credentials(record)
    validate_github_id(record)
    validate_github_client_notifications_scope(record)
    validate_github_client_read_scope(record)
  end

  private

  def validate_tokens_are_enabled(record)
    unless Octobox.personal_access_tokens_enabled?
      record.errors.add(*ERRORS[:disallowed_tokens])
    end
  end

  def validate_token_credentials(record)
    valid_credentials = Octokit::Client.new.validate_credentials(
      access_token: record.effective_access_token)
    record.errors.add(*ERRORS[:invalid_token]) unless valid_credentials
  end

  def validate_github_id(record)
    unless record.github_id == record.github_client.user.id
      record.errors.add(*ERRORS[:invalid_token])
    end
  end

  def validate_github_client_notifications_scope(record)
    unless record.github_client.scopes.include? 'notifications'
      record.errors.add(*ERRORS[:missing_notifications_scope])
    end
  end

  def validate_github_client_read_scope(record)
    if Octobox.restricted_access_enabled? && !record.github_client.scopes.include?('read:org')
      record.errors.add(*ERRORS[:missing_read_org_scope])
    end
  end
end
