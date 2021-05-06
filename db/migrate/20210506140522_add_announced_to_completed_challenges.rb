class AddAnnouncedToCompletedChallenges < ActiveRecord::Migration[5.2]
  def change
    add_column :completed_challenges, :announced, :boolean, default: false
  end
end
