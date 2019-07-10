class AddReviewStateToComments < ActiveRecord::Migration[5.2]
  def change
  	add_column :comments, :review_state, :string
  end
end
