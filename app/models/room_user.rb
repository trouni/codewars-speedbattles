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
  after_commit :broadcast_user
  # validates :user, uniqueness: { scope: :room }
  validates :user, uniqueness: true

  private

  def async_fetch_info
    user.async_fetch_codewars_info if user.last_fetched_at.nil? || Time.now - user.last_fetched_at > 60.minutes
  end

  def broadcast_user
    room.broadcast_user(action: "add", user: user)
  end
end
