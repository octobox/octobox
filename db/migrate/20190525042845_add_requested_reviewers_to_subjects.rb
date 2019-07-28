class AddRequestedReviewersToSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :subjects, :requested_reviewers, :string, default: '::'
  end
end
