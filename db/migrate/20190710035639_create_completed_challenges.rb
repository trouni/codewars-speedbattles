class CreateCompletedChallenges < ActiveRecord::Migration[5.2]
  def change
    create_table :completed_challenges do |t|
      t.references :user, foreign_key: true
      t.string :challenge_id
      t.string :challenge_name
      t.string :challenge_slug
      t.datetime :completed_at
      t.string :completed_languages

      t.timestamps
    end
  end
end
