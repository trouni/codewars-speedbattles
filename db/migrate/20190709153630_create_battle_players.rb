class CreateBattlePlayers < ActiveRecord::Migration[5.2]
  def change
    create_table :battle_players do |t|
      t.references :battle, foreign_key: true
      t.references :player, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
