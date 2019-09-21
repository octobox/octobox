class AddRequestedTeamsToSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :subjects, :requested_teams, :string, default: '::'
  end
end
