class AddPrivateToRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :rooms, :private, :boolean, default: true
  end
end
