class AddSoundToRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :rooms, :sound, :string, default: 'everyone'
  end
end
