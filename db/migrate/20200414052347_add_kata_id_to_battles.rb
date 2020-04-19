class AddKataIdToBattles < ActiveRecord::Migration[5.2]
  def change
    add_reference :battles, :kata, foreign_key: true
  end
end
