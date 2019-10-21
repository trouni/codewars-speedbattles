class AddColumnToRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :rooms, :show_stats, :boolean, default: true
  end
end
