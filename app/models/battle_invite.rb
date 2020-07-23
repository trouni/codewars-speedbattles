# == Schema Information
#
# Table name: battle_invites
#
#  id         :bigint           not null, primary key
#  confirmed  :boolean          default(FALSE)
#  survived   :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  battle_id  :bigint
#  player_id  :bigint
#

class BattleInvite < ApplicationRecord
  belongs_to :battle
  has_one :room, through: :battle
  belongs_to :player, class_name: "User"
  validates :player, uniqueness: { scope: :battle }
  # after_commit :broadcast_user, only: :destroy

  def broadcast_user
    user = User.find(player_id)
    room.broadcast_user(user: user)
  end

  def broadcast_battles
    room.broadcast_battles
  end
end
