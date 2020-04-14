class AddKataIdToCompletedChallenges < ActiveRecord::Migration[5.2]
  def change
    add_reference :completed_challenges, :kata, foreign_key: true
  end
end
