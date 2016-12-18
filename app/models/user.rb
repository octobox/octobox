# frozen_string_literal: true
class User < ApplicationRecord
  has_many :notifications

  validates :access_token, presence: true, uniqueness: true
  validates :github_id,    presence: true, uniqueness: true

end
