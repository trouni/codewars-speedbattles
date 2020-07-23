class RemoveColumnsFromCompletedChallenges < ActiveRecord::Migration[5.2]
  def change
    remove_column :completed_challenges, :challenge_id, :string
    remove_column :completed_challenges, :challenge_name, :string
    remove_column :completed_challenges, :challenge_slug, :string
  end
end
