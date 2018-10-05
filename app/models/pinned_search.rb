# frozen_string_literal: true
class PinnedSearch < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :query, presence: true
  validates :name, presence: true
end
