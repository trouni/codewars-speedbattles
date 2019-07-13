class CreateBattleInvites < ActiveRecord::Migration[5.2]
  def change
    create_table :battle_invites do |t|
      t.references :battle, foreign_key: true
      t.references :player, foreign_key: { to_table: :users }
      t.boolean :confirmed, default: false
      t.boolean :survived

      t.timestamps
    end
  end
end
