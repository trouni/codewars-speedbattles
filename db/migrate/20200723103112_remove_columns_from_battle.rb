class RemoveColumnsFromBattle < ActiveRecord::Migration[5.2]
  def change
    remove_column :battles, :challenge_id, :string
    remove_column :battles, :challenge_url, :string
    remove_column :battles, :challenge_name, :string
    remove_column :battles, :challenge_rank, :string
    remove_column :battles, :challenge_description, :text
    remove_reference :battles, :winner, foreign_key: { to_table: :users }
  end
end
