# == Schema Information
#
# Table name: users
#
#  id                            :bigint           not null, primary key
#  email                         :string           default(""), not null
#  encrypted_password            :string           default(""), not null
#  reset_password_token          :string
#  reset_password_sent_at        :datetime
#  remember_created_at           :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  username                      :string
#  name                          :string
#  admin                         :boolean          default(FALSE)
#  codewars_honor                :integer
#  codewars_clan                 :string
#  codewars_leaderboard_position :integer
#  codewars_overall_rank         :integer
#  codewars_overall_score        :integer
#  last_fetched_at               :datetime
#

class User < ApplicationRecord
  has_many :room_users
  has_many :rooms, through: :room_users
  has_many :battle_players, foreign_key: 'player_id'
  has_many :battles, through: :battle_players
  has_many :battles_as_winner, class_name: 'Battle', foreign_key: 'winner_id'
  has_many :completed_challenges, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :async_fetch_cw_info

  private

  def async_fetch_cw_info
    FetchUserInfoJob.perform_later(self)
    FetchCompletedChallengesJob.perform_later(self)
  end
end
