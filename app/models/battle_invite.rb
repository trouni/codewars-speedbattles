# == Schema Information
#
# Table name: battle_invites
#
#  id         :bigint           not null, primary key
#  battle_id  :bigint
#  player_id  :bigint
#  confirmed  :boolean          default(FALSE)
#  survived   :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class BattleInvite < ApplicationRecord
  belongs_to :battle
  has_one :room, through: :battle
  belongs_to :player, class_name: "User"
  # after_commit :broadcast_user, :broadcast_battles

  def broadcast_user
    user = User.find(player_id)
    room.broadcast_user(user: user)
  end

  def broadcast_battles
    room.broadcast_battles
  end
end
