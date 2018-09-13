class Repository < ApplicationRecord
  has_many :notifications, foreign_key: :repository_full_name, primary_key: :full_name
  has_many :users, -> { distinct }, through: :notifications
  has_many :subjects, foreign_key: :repository_full_name, primary_key: :full_name
  belongs_to :app_installation

  validates :full_name, presence: true, uniqueness: true
  validates :github_id, uniqueness: true

  scope :github_app_installed, -> { joins(:app_installation) }

  def github_app_installed?
    app_installation_id.present?
  end
end
