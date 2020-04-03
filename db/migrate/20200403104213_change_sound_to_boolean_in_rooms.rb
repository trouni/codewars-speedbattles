class ChangeSoundToBooleanInRooms < ActiveRecord::Migration[5.2]
  def change
    remove_column :rooms, :sound, :string
    add_column :rooms, :sound, :boolean, default: true
  end
end
