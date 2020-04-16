class Kata < ApplicationRecord
  has_many :completed_challenges
  has_many :users, through: :completed_challenges
  validates :codewars_id, presence: true, uniqueness: true

  def async_fetch_kata_info
    FetchKataInfoJob.perform_later(codewars_id)
  end
end
