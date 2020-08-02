# == Schema Information
#
# Table name: room_users
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  room_id    :bigint
#  user_id    :bigint
#

class RoomUser < ApplicationRecord
  belongs_to :room
  belongs_to :user
  after_create :async_fetch_info
  after_commit :broadcast_user
  after_destroy :broadcast_disconnect, :cancel_invite
  # validates :user, uniqueness: { scope: :room }
  validates :user, uniqueness: true

  private

  def async_fetch_info
    user.async_fetch_codewars_info if user.last_fetched_at.nil? || Time.now - user.last_fetched_at > 60.minutes
  end

  def broadcast_user
    room.broadcast_user(action: "add", user: user)
  end

  def broadcast_disconnect
    room.broadcast_user(action: "remove", user: user)
  end

  def cancel_invite
    # Cancel battle invite unless the battle already started
    unless room.active_battle.nil? || room.active_battle.started?
      room.active_battle.invites.find_by(player: user)&.destroy
    end
  end
end
