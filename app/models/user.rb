# == Schema Information
#
# Table name: users
#
#  id                            :bigint           not null, primary key
#  email                         :string           default(""), not null
#  username                      :string           default(""), not null
#  encrypted_password            :string           default(""), not null
#  reset_password_token          :string
#  reset_password_sent_at        :datetime
#  remember_created_at           :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
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
  acts_as_token_authenticatable
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

  after_create :async_fetch_codewars_info

  def survived_battle?(battle)
    return nil if battle.players.exclude?(self)

    CompletedChallenge.where(
      "completed_at < ? AND challenge_id = ? AND user_id = ?",
      battle.end_time,
      battle.challenge_id,
      id
    ).any?
  end

  def eligible_for_battle?(battle)
    CompletedChallenge.where(
      "challenge_id = ? AND user_id = ?",
      battle.challenge_id,
      id
    ).count.zero?
  end

  private

  def async_fetch_codewars_info
    FetchUserInfoJob.perform_later(self.id)
    FetchCompletedChallengesJob.perform_later(self.id)
  end
end
