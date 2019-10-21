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
  after_create :async_fetch_challenges
  after_create_commit :join_room
  after_destroy_commit :leave_room
  validates :user, uniqueness: { scope: :room }

  private

  def async_fetch_challenges
    FetchCompletedChallengesJob.perform_later(user_id: user_id)
  end

  def join_room
    room.broadcast_user(action: "add", user: user)
  end

  def leave_room
    room.broadcast_user(action: "remove", user: user)
  end
end
