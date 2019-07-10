# == Schema Information
#
# Table name: battle_players
#
#  id         :bigint           not null, primary key
#  battle_id  :bigint
#  player_id  :bigint
#  confirmed  :boolean          default(FALSE)
#  survived   :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class BattlePlayer < ApplicationRecord
  belongs_to :battle
  belongs_to :player, class_name: "User"
end
