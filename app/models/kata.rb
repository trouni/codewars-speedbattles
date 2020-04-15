class Kata < ApplicationRecord
  validates :codewars_id, presence: true, uniqueness: true
  after_create :async_fetch_kata_info

  def async_fetch_kata_info
    FetchKataInfoJob.perform_later(codewars_id)
  end
end
