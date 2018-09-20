module Octobox
	module Repository
		module UpdateNotificationRepositoryName
			extend ActiveSupport::Concern

			included do
				after_update :upate_full_name_and_owner, if: -> { saved_change_to_full_name? }
			end

			# update full_name and owner_name of notifications if Repository full_name is updated
			def upate_full_name_and_owner
				notifications = Notification.where(repository_id: self.github_id)

				return if notifications.blank?

				updated_notifications = notifications.each do |notification|
					notification.repository_full_name = self.full_name
					notification.repository_owner_name =  self.owner
				end

        # bulk update using activerecord-import gem
        # on duplicate key option will update the notification attrs instead to creating one
				Notification.import updated_notifications, :batch_size => 1000,
				on_duplicate_key_update: {
					conflict_target: [:id], columns: [:repository_full_name, :repository_owner_name]
				}
			end

		end
	end
end