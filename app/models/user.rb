# frozen_string_literal: true
class User < ApplicationRecord
  has_many :notifications

  validates :access_token, presence: true, uniqueness: true
  validates :github_id,    presence: true, uniqueness: true

  def self.find_by_auth_hash(auth_hash)
    User.find_by(github_id: auth_hash['uid'])
  end

  def assign_from_auth_hash(auth_hash)
    github_attributes = {
      github_id: auth_hash['uid'],
      access_token: auth_hash.dig('credentials', 'token')
    }

    update_attributes(github_attributes)
  end
end
