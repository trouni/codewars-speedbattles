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
  belongs_to :player, class_name: "User"
  after_commit :broadcast_invite_status

  def broadcast_invite_status
    player.broadcast_user_status(battle.room)
  end
end
