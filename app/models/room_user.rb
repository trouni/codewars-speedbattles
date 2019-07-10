class RoomUser < ApplicationRecord
  belongs_to :room
  belongs_to :user
  after_create :async_fetch_codewars_info

  private

  def async_fetch_codewars_info
    FetchCompletedChallengesJob.perform_later(self.user)
  end
end
