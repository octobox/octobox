# frozen_string_literal: true
class PinnedSearch < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :query, presence: true
  validates :name, presence: true

  before_commit :format_query, on: [:create, :update]

  def format_query
    return unless self.query.present?
    # ensures consistent formatting by formatting with Search.new
    self.query = Search.new(query: self.query, scope: {}).to_query
  end
end
