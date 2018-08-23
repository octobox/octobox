class Repository < ApplicationRecord
  has_many :notifications, foreign_key: :repository_full_name, primary_key: :full_name

  validates :full_name, presence: true, uniqueness: true
  validates :github_id, uniqueness: true

  def subjects
    Subject.repository(full_name)
  end
end
