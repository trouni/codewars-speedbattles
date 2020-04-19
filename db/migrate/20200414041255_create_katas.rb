class CreateKatas < ActiveRecord::Migration[5.2]
  def change
    create_table :katas do |t|
      t.string :codewars_id
      t.string :name
      t.string :slug
      t.string :category
      t.string :languages, array: true, default: []
      t.string :url
      t.integer :rank
      t.integer :total_attempts
      t.integer :total_completed
      t.integer :total_stars
      t.integer :vote_score
      t.integer :satisfaction_rating
      t.integer :total_votes
      t.datetime :last_scraped_at
      t.string :tags, array: true, default: []
      t.jsonb :other

      t.timestamps
    end
  end
end
