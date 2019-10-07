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
require 'json'
require 'open-uri'

class User < ApplicationRecord
  acts_as_token_authenticatable
  has_one :room_user, required: false
  has_one :room, through: :room_user, required: false
  has_many :rooms_as_moderator, class_name: "Room", foreign_key: 'moderator_id'
  has_many :battle_invites, foreign_key: 'player_id'
  has_many :battles, through: :battle_invites do
    def for_room(room)
      where(room_id: room.id)
    end
  end
  has_many :battles_as_winner, class_name: 'Battle', foreign_key: 'winner_id'
  has_many :completed_challenges, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  before_validation :create_email, on: :create
  after_create :async_fetch_codewars_info, :create_email2

  def email_required?
    false
  end

  def api_expose(for_room = room)
    standard_result = {
      id: id,
      invite_status: invite_status(for_room),
      last_fetched_at: last_fetched_at,
      name: name,
      username: username
    }
    # return standard_result unless for_room

    # return standard_result.merge stats
  end

  def stats
    return {} unless room

    result =
    api_expose.merge(battles_survived: survived(room).size)
              .merge(battles_fought: battles.for_room(room).size)
              .merge(completed_at: active_battle&.completed_challenge_at(self))
              .merge(victories: room.victories(self).size)
              .merge(total_score: room.total_score(self))
    # {
    #   battles_fought: battles.for_room(room).size,
    #   battles_survived: survived(room).size,
    #   victories: room.victories(self).size,
    #   total_score: room.total_score(self),
    #   completed_at: active_battle&.completed_challenge_at(self)
    # }
  end

  def self.valid_username?(username)
    url = "https://www.codewars.com/api/v1/users/#{username}"
    puts "Fetching data from #{url}"
    json = JSON.parse(open(url).read)
    return json["username"] == username
  rescue
    return false
  end

  def moderator?(for_room = room)
    rooms_as_moderator.include?(for_room)
  end

  def self.find_or_create_bot
    bot = User.find_or_initialize_by(username: "bot", email: "bot@speedbattles.com")
    bot.password ||= "secret"
    bot.save
    return bot
  end

  # def active_room
  #   RoomUser.includes(:room).joins(:room).find_by(user: self)&.room
  # end

  def active_battle
    room&.active_battle
  end

  def invited?(battle = active_battle)
    return nil unless battle

    BattleInvite.where(battle: battle, player: self).exists?
  end

  def confirmed?(battle = active_battle)
    return nil unless battle

    BattleInvite.where(battle: battle, player: self, confirmed: true).exists?
  end

  def eligible?(battle = active_battle)
    return nil unless battle

    !completed_challenge?(battle.challenge_id) && !moderator? && !battle.started?
  end

  def completed_challenge?(challenge_id)
    completed_challenges.where(challenge_id: challenge_id).exists?
  end

  def survived?(battle)
    completed_challenges.includes(user: :battles)
                        .joins(user: :battles)
                        .where(challenge_id: battle.challenge_id)
                        .where("completed_at > ? AND completed_at < ?", battle.start_time, battle.end_time)
                        .exists?
  end

  def survived(room = nil)
    result =
    battles.includes(:players, players: :completed_challenges)
          .joins(:players, players: :completed_challenges)
          .where("battles.challenge_id = completed_challenges.challenge_id AND completed_challenges.user_id = ?", self.id)
          .where("completed_challenges.completed_at > battles.start_time AND completed_challenges.completed_at < battles.end_time")

    return result unless room

    return result.includes(:room).joins(:room).where(rooms: { id: room.id })
    # CompletedChallenge.includes(:user)
    #                   .joins(:user)
    #                   .where(challenge_id: challenge_id, user: self)
    #                   .where("completed_at > ? AND completed_at < ?", start_time, end_time)
    #                   .order(completed_at: :asc).first
  end

  # def won(room = room)
  #   result =
  #   battles.includes(:players, players: :completed_challenges)
  #         .joins(:players, players: :completed_challenges)
  #         .where("battles.challenge_id = completed_challenges.challenge_id AND completed_challenges.user_id = ?", self.id)
  #         .where("completed_challenges.completed_at > battles.start_time AND completed_challenges.completed_at < battles.end_time")
  # end

  def invite_status(room)
    return nil unless room && room.active_battle

    if confirmed?(room.active_battle)
      "confirmed"
    elsif invited?(room.active_battle)
      "invited"
    elsif eligible?(room.active_battle)
      "eligible"
    else
      "ineligible"
    end
  end

  def async_fetch_codewars_info
    FetchUserInfoJob.perform_later(id)
    FetchCompletedChallengesJob.perform_later(user_id: id, all_pages: true)
  end

  def create_email
    self.email = "#{username}@me.com"
  end

  def create_email2
    update(email: "#{username}@me.com")
  end
end
