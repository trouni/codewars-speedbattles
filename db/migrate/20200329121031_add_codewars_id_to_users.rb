class AddCodewarsIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :codewars_id, :string
    add_column :users, :connected_webhook, :boolean, default: false
  end
end
