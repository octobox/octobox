# frozen_string_literal: true
class User < ApplicationRecord
  has_many :notifications

  validates :github_id,    presence: true, uniqueness: true
  validates :access_token, presence: true, uniqueness: true
  validates :github_login, presence: true

  after_create :sync_notifications

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

  def archive_all
    notifications.each { |n| n.update_attributes(archived: true) }
  end

  def sync_notifications
    Notification.download(self)
  end

  def github_client
    return @github_client if defined?(@github_client)
    @github_client = Octokit::Client.new(access_token: access_token, auto_paginate: true)
  end
end
