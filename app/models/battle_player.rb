class BattlePlayer < ApplicationRecord
  belongs_to :battle
  belongs_to :player, class_name: "User"
end
