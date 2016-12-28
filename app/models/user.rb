# frozen_string_literal: true
class User < ApplicationRecord
  has_many :notifications, dependent: :delete_all

  validates :github_id,    presence: true, uniqueness: true
  validates :access_token, presence: true, uniqueness: true
  validates :github_login, presence: true
  validate :personal_access_token_validator

  after_commit :sync_notifications, on: :create

  ERRORS = {
    invalid_token: [:personal_access_token, 'is not a valid token for this github user'],
    missing_scope: [:personal_access_token, 'does not include the notifications scope']
  }.freeze

  def self.find_by_auth_hash(auth_hash)
    User.find_by(github_id: auth_hash['uid'])
  end

  def assign_from_auth_hash(auth_hash)
    github_attributes = {
      github_id: auth_hash['uid'],
      github_login: auth_hash['info']['nickname'],
      access_token: auth_hash.dig('credentials', 'token')
    }

    update_attributes(github_attributes)
  end

  def sync_notifications
    Notification.download(self)
  end

  def github_client
    unless defined?(@github_client) && effective_access_token == @github_client.access_token
      @github_client = Octokit::Client.new(access_token: effective_access_token, auto_paginate: true)
    end
    @github_client
  end

  def github_avatar_url
    domain = ENV.fetch('GITHUB_DOMAIN', 'https://github.com')
    "#{domain}/#{github_login}.png"
  end

  def effective_access_token
    personal_access_token.present? ? personal_access_token : access_token
  end

  def personal_access_token_validator
    return unless personal_access_token.present?
    unless Octokit::Client.new.validate_credentials(access_token: effective_access_token)
      errors.add(*ERRORS[:invalid_token])
      return
    end
    unless github_id == github_client.user.id
      errors.add(*ERRORS[:invalid_token])
      return
    end
    unless github_client.scopes.include? 'notifications'
      errors.add(*ERRORS[:missing_scope])
    end
  end

end
