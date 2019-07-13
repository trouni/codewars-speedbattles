# == Schema Information
#
# Table name: rooms
#
#  id           :bigint           not null, primary key
#  name         :string
#  moderator_id :bigint
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Room < ApplicationRecord
  belongs_to :moderator, class_name: "User"
  has_many :room_users, dependent: :destroy
  has_many :users, through: :room_users
  has_many :battles
  validates :name, presence: true

  def active_battle
    Battle.where(room: self).find_by(end_time: nil)
  end

  def active_battle?
    active_battle.present?
  end

  def finished_battles
    battles.where.not(end_time: nil)
  end

  def last_battle
    finished_battles.order(end_time: :asc).last
  end

  # Room has no battle set up
  def at_peace?
    active_battle.nil?
  end

  # Room has an ongoing battle (started but not finished)
  def at_war?
    active_battle.present? && active_battle.start_time.present?
  end

  # Room has a pending battle (set up but not yet started)
  def brink_of_war?
    active_battle.present? && !at_war?
  end

  def battle_status
    if at_peace?
      "at_peace"
    elsif brink_of_war?
      "brink_of_war"
    elsif at_war?
      "at_war"
    end
  end
end
