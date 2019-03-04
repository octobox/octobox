class DisplayCommentsInOcotobox < ActiveRecord::Migration[5.2]
	def change
		change_column :users, :display_comments, :boolean, default: true
	end
end
