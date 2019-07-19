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
#  authentication_token          :string(30)
#

class User < ApplicationRecord
  acts_as_token_authenticatable
  has_one :room_user, required: false
  has_one :room, through: :room_user, required: false
  has_many :rooms_as_moderator, class_name: "Room", foreign_key: 'moderator_id'
  has_many :battle_invites, foreign_key: 'player_id'
  has_many :battles, through: :battle_invites
  has_many :battles_as_winner, class_name: 'Battle', foreign_key: 'winner_id'
  has_many :completed_challenges, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :async_fetch_codewars_info

  def api_expose
    {
      id: id,
      invite_status: invite_status,
      last_fetched_at: last_fetched_at,
      name: name,
      username: username
    }
  end

  def moderator?(for_room = room)
    rooms_as_moderator.include?(for_room)
  end

  def survived_battle?(battle)
    return nil if battle.players.exclude?(self)

    CompletedChallenge.where(
      "completed_at < ? AND challenge_id = ? AND user_id = ?",
      battle.end_time,
      battle.challenge_id,
      id
    ).any?
  end

  def active_battle
    room&.active_battle
  end

  def active_battle_invite
    BattleInvite.where(battle: battle, player: self)
  end

  def invited?(battle = active_battle)
    return nil unless battle

    BattleInvite.where(battle: battle, player: self).any?
  end

  def confirmed?(battle = active_battle)
    return nil unless battle

    BattleInvite.where(battle: battle, player: self, confirmed: true).any?
  end

  def eligible?(battle = active_battle)
    return nil unless battle

    CompletedChallenge.where(challenge_id: battle.challenge_id, user_id: id).empty?
  end

  def invite_status(battle = active_battle)
    return nil unless battle

    if confirmed?(battle)
      "confirmed"
    elsif invited?(battle)
      "invited"
    elsif eligible?(battle)
      "eligible"
    else
      "ineligible"
    end
  end

  def async_fetch_codewars_info
    FetchUserInfoJob.perform_later(id)
    FetchCompletedChallengesJob.perform_later(id)
  end

  def broadcast_user_status(room)
    ActionCable.server.broadcast(
      "room_#{room.id}",
      api_expose
    )
  end

  def broadcast_user_unsubscribe(room)
    ActionCable.server.broadcast(
      "room_#{room.id}",
      api_expose.merge(unsubscribed: true)
    )
  end
end
