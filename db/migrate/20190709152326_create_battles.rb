class CreateBattles < ActiveRecord::Migration[5.2]
  def change
    create_table :battles do |t|
      t.references :room, foreign_key: true
      t.string :challenge_id
      t.string :challenge_url
      t.string :challenge_name
      t.string :challenge_language
      t.integer :challenge_rank
      t.text :challenge_description
      t.boolean :sudden_death
      t.integer :max_survivors
      t.integer :time_limit
      t.datetime :end_time
      t.datetime :start_time
      t.references :winner, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
