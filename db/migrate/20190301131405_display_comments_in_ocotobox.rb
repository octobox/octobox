class DisplayCommentsInOcotobox < ActiveRecord::Migration[5.2]
  def up
  	User.all.find_each do |user|
  		user.update_attribute(:display_comments, true)
  	end
  end

  def down
  	User.all.find_each do |user|
  		user.update_attribute(:display_comments, false)
  	end
  end
end
