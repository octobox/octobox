module Octobox
  module Repository
    module UpdateNotificationRepositoryName
      extend ActiveSupport::Concern

      included do
        after_update :update_full_name_and_owner, if: :saved_change_to_full_name?
      end

      # update full_name and owner_name of notifications if Repository full_name is updated
      def update_full_name_and_owner
        # bulk update notifications
        # Note: This method constructs a single SQL UPDATE statement and sends it straight
        # to the database so it will not update the timestamps
        Notification.where(repository_id: self.github_id).update_all({
          repository_full_name: self.full_name,
          repository_owner_name:  self.owner
        })
      end
    end
  end
end
