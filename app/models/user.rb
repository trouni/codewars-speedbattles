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

# Attempt at making one request for all scores:
# <<-SQL
# SELECT COUNT(*)
# FROM users
# WHERE users.id IN (
#   SELECT player_id
#   FROM battle_invites
#   WHERE battle_invites.battle_id = 1
#   AND battle_invites.player_id = 1
#   AND battle_invites.confirmed = true
# );

# SELECT battles.id as battle_id, users.id as user_id, users.username as username,
#   SUM(CASE WHEN EXISTS (SELECT 1 FROM battle_invites WHERE battle_invites.player_id = users.id AND battle_invites.battle_id = battles.id) THEN 1 ELSE 0 END) Invited,
#   SUM(CASE WHEN battle_invites.confirmed = true THEN 1 ELSE 0 END) as Confirmed,
#   SUM(CASE WHEN battle_invites.confirmed = true THEN 1 ELSE 0 END) as Eligible,
#   SUM(CASE WHEN battle_invites.confirmed = true THEN 1 ELSE 0 END) as Ineligible,
#   completed_at = (SELECT completed_challenges.completed_at FROM completed_challenges WHERE completed_challenges.user_id = users.id AND battles.challenge_id = completed_challenges.challenge_id AND completed_challenges.completed_at > battles.start_time AND completed_challenges.completed_at < battles.end_time LIMIT 1) AS completed_at,
#   SUM(CASE WHEN (battles.challenge_id = completed_challenges.challenge_id AND completed_challenges.completed_at > battles.start_time AND completed_challenges.completed_at < battles.end_time) THEN 1 ELSE 0 END) as Survived,
#   SUM(CASE WHEN (battle_invites.player_id = users.id) THEN 1 ELSE 0 END) as Fought

# FROM users
# LEFT JOIN battle_invites ON battle_invites.player_id = users.id
# LEFT JOIN battles ON battle_invites.battle_id = battles.id
# LEFT JOIN completed_challenges ON completed_challenges.user_id = users.id
# GROUP BY battles.id, users.id
# SQL

class User < ApplicationRecord
  acts_as_token_authenticatable
  has_one :room_user, required: false
  has_one :room, through: :room_user, required: false
  has_many :rooms_as_moderator, class_name: "Room", foreign_key: 'moderator_id'
  has_many :battle_invites, foreign_key: 'player_id'
  has_many :battles, through: :battle_invites do
    def for_room(room)
      where(room_id: room.id, battle_invites: { confirmed: true }).where.not(end_time: nil)
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

  def api_expose(for_room = room, battle = active_battle)
    standard_result = {
      id: id,
      username: username,
      name: name,
      last_fetched_at: last_fetched_at,
      invite_status: invite_status(battle),
      completed_at: battle&.completed_challenge_at(self)
    }

    no_stats = {
      battles_survived: nil,
      battles_fought: nil,
      victories: nil,
      total_score: nil
    }
    return standard_result.merge(no_stats) unless for_room

    return standard_result.merge(battles_survived: survived(for_room).size)
                          .merge(battles_fought: battles.for_room(for_room).size)
                          .merge(victories: for_room.victories(self).size)
                          .merge(total_score: for_room.total_score(self))
                          # .merge(completed_at: active_battle&.completed_challenge_at(self))
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

    !completed_challenge?(battle.challenge_id) && !moderator?
  end

  def completed_challenge?(challenge_id)
    completed_challenges.where(challenge_id: challenge_id).exists?
  end

  def survived?(battle)
    end_time = battle.end_time || DateTime.now

    completed_challenges.includes(user: :battles)
                        .joins(user: :battles)
                        .where(challenge_id: battle.challenge_id)
                        .where("completed_at > ? AND completed_at < ?", battle.start_time, end_time)
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

  def invite_status(battle = active_battle)
    return nil if !room || room.at_peace?

    if survived?(battle)
      "survived"
    elsif confirmed?(battle)
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
    FetchCompletedChallengesJob.perform_later(user_id: id, all_pages: true)
  end

  def create_email
    self.email = "#{username}@me.com"
  end

  def create_email2
    update(email: "#{username}@me.com")
  end
end
