class AddIndexOnCompletedChallenges < ActiveRecord::Migration[5.2]
  def change
    add_index :completed_challenges, :challenge_id
  end
end
