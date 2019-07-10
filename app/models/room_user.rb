# == Schema Information
#
# Table name: room_users
#
#  id         :bigint           not null, primary key
#  room_id    :bigint
#  user_id    :bigint
#  player     :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class RoomUser < ApplicationRecord
  belongs_to :room
  belongs_to :user
  after_create :async_fetch_codewars_info

  private

  def async_fetch_codewars_info
    FetchCompletedChallengesJob.perform_later(self.user)
  end
end
