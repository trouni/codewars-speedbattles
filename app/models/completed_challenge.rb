# == Schema Information
#
# Table name: completed_challenges
#
#  id                  :bigint           not null, primary key
#  user_id             :bigint
#  challenge_id        :string
#  challenge_name      :string
#  challenge_slug      :string
#  completed_at        :datetime
#  completed_languages :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class CompletedChallenge < ApplicationRecord
  belongs_to :user
  validates :challenge_id, uniqueness: { scope: %i[user completed_at] }
  after_create :update_active_battle

  def api_expose
    {
      id: id,
      user_id: user.id,
      challenge_id: challenge_id,
      challenge_name: challenge_name,
      challenge_slug: challenge_slug,
      completed_at: completed_at,
      completed_languages: completed_languages
    }
  end

  def update_active_battle
    room = user.active_battle&.room
    room&.broadcast_active_battle
  end
end
