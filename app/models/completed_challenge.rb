class CompletedChallenge < ApplicationRecord
  belongs_to :user
  validates :challenge_id, uniqueness: { scope: %i[user completed_at] }
end
