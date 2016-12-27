# frozen_string_literal: true
class User < ApplicationRecord
  has_many :notifications, dependent: :delete_all

  validates :github_id,    presence: true, uniqueness: true
  validates :access_token, presence: true, uniqueness: true
  validates :github_login, presence: true

  after_commit :sync_notifications, on: :create

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
    return @github_client if defined?(@github_client)
    @github_client = Octokit::Client.new(access_token: access_token, auto_paginate: true)
  end

  def github_avatar_url
    domain = ENV.fetch('GITHUB_DOMAIN', 'https://github.com')
    "#{domain}/#{github_login}.png"
  end

end
