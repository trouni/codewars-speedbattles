class Battle < ApplicationRecord
  belongs_to :room
  belongs_to :winner, class_name: "User", optional: true
  has_many :battle_players, dependent: :destroy
  has_many :players, through: :battle_players, class_name: "User"
end
