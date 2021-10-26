# frozen_string_literal: true
class PinnedSearch < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :query, presence: true
  validates :name, presence: true

  before_validation :format_query, on: [:create, :update]

  def format_query
    return unless self.query.present?
    # ensures consistent formatting by formatting with Search.new
    self.query = Search.new(query: self.query, scope: {}).to_query
  end

  def results(user)
    Search.initialize_for_saved_search(query: query, user: user).results
  end
end
