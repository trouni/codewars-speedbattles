# == Schema Information
#
# Table name: battles
#
#  id              :bigint           not null, primary key
#  room_id         :bigint
#  challenge_id    :string
#  sudden_death    :boolean
#  max_survivors :integer
#  time_limit      :integer
#  archived        :boolean
#  start_time      :datetime
#  winner_id       :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Battle < ApplicationRecord
  belongs_to :room
  belongs_to :winner, class_name: "User", optional: true
  has_many :battle_players, dependent: :destroy
  has_many :players, through: :battle_players, class_name: "User"
end
