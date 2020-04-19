# == Schema Information
#
# Table name: completed_challenges
#
#  id                  :bigint           not null, primary key
#  user_id             :bigint
#  DELETE: challenge_id        :string
#  DELETE: challenge_name      :string
#  DELETE: challenge_slug      :string
#  completed_at        :datetime
#  completed_languages :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class CompletedChallenge < ApplicationRecord
  belongs_to :user
  belongs_to :kata, required: false
  validates :challenge_id, uniqueness: { scope: %i[user completed_at] }
  validates :kata_id, uniqueness: { scope: %i[user completed_at] }
  # after_create :update_active_battle

  def update_active_battle
    room = user.active_battle&.room
    room&.broadcast_active_battle
    room&.broadcast_player(user: user)
  end
end
