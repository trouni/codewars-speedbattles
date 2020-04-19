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
  after_create :async_fetch_info
  after_create_commit :join_room
  after_destroy_commit :leave_room
  # validates :user, uniqueness: { scope: :room }
  validates :user, uniqueness: true

  private

  def async_fetch_info
    user.async_fetch_codewars_info if user.last_fetched_at.nil? || Time.now - user.last_fetched_at > 60.minutes
  end

  def join_room
    room.broadcast_user(action: "add", user: user)
  end

  def leave_room
    room.broadcast_user(action: "remove", user: user)
  end
end
