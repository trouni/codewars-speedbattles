class AddInfoToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :username, :string
    add_column :users, :name, :string
    add_column :users, :codewars_honor, :integer
    add_column :users, :codewars_clan, :string
    add_column :users, :codewars_leaderboard_position, :integer
    add_column :users, :codewars_overall_rank, :integer
    add_column :users, :codewars_overall_score, :integer
    add_column :users, :last_fetched_at, :datetime
  end
end
