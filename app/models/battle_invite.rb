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
  # after_create :broadcast_user
  after_destroy :broadcast_user
  after_commit :broadcast_user, if: :saved_change_to_confirmed?

  def broadcast_user
    user = User.find(player_id)
    room.broadcast_user(user: user)
    room.broadcast_active_battle if battle.confirmed_players.count <= battle.min_players
    battle.destroy if battle.invites.empty?
  end
end
