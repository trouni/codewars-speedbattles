class CreateBattles < ActiveRecord::Migration[5.2]
  def change
    create_table :battles do |t|
      t.references :room, foreign_key: true
      t.string :challenge_id
      t.boolean :elimnation_round
      t.integer :spots_available
      t.datetime :start_time
      t.references :winner, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
