class CreateRooms < ActiveRecord::Migration[5.2]
  def change
    create_table :rooms do |t|
      t.string :name
      t.references :master, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
