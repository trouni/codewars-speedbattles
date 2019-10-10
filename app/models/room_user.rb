# == Schema Information
#
# Table name: room_users
#
#  id         :bigint           not null, primary key
#  room_id    :bigint
#  user_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class RoomUser < ApplicationRecord
  belongs_to :room
  belongs_to :user
  after_create :async_fetch_codewars_info
  after_create_commit :join_room
  after_destroy_commit :leave_room
  validates :user, uniqueness: { scope: :room }

  private

  def async_fetch_codewars_info
    # FetchCompletedChallengesJob.perform_later(user.id)
    user.async_fetch_codewars_info
  end

  def join_room
    room.broadcast_active_battle
    room.broadcast_user(action: "add", user: user)
  end

  def leave_room
    # BattleInvite.find_by(battle: room.active_battle, player: user, confirmed: false)&.destroy
    room.broadcast_active_battle
    room.broadcast_user(action: "remove", user: user)
  end
end
