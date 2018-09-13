class AppInstallationPermission < ApplicationRecord
  belongs_to :app_installation
  belongs_to :user

  validates :app_installation_id, presence: true
  validates :user_id, presence: true
end
