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
      where(room_id: room.id, battle_invites: { confirmed: true }).where.not(end_time: nil)
    end
  end
  has_many :completed_challenges, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :async_fetch_codewars_info

  scope :invited, ->(battle) { battle ? self.in(battle.room).select('battle_invites.created_at AS invited_at').joins(:battle_invites).where(battle_invites: { battle: battle }) : [] }
  scope :pending, ->(battle) { battle ? invited(battle).where(battle_invites: { confirmed: false }) : [] }
  scope :confirmed, ->(battle) { battle ? invited(battle).where(battle_invites: { confirmed: true }) : [] }

  def self.in(room)
    joins(:room_user).where(room_users: { room: room })
                     .select('users.id, users.username, users.name, users.last_fetched_at, room_users.created_at AS joined_at')
  end

  def self.ineligible(room)
    return self.in(room) unless room.active_battle

    self.in(room).select('completed_challenges.completed_at')
        .joins(:completed_challenges)
        .where(completed_challenges: { challenge_id: room.active_battle.challenge_id })
  end

  def self.eligible(room)
    return [] unless room.active_battle

    self.in(room)
        .where('users.id NOT IN (?)', ineligible(room).pluck(:id))
  end

  def self.survived(battle)
    return [] unless battle

    confirmed(battle).select('completed_challenges.completed_at')
                     .joins(:battles, :completed_challenges)
                     .where(<<-SQL, battle.challenge_id)
                     completed_challenges.challenge_id = ?
                     AND completed_challenges.completed_at > battles.start_time
                     AND completed_challenges.completed_at < battles.end_time
                     SQL
  end

  def self.defeated(battle)
    return [] unless battle

    confirmed(battle).where('users.id NOT IN (?)', survived(battle).pluck(:id))
  end

  def api_expose(for_room = room, battle = active_battle)
    standard_result = {
      id: id,
      username: username,
      name: name,
      last_fetched_at: last_fetched_at,
      invite_status: invite_status(battle),
      invited_at: active_invite(battle)&.created_at,
      joined_at: room_user&.created_at,
      completed_at: battle&.completed_challenge_at(self)
    }

    no_stats = { battles_survived: nil, battles_fought: nil, total_score: nil }

    return standard_result unless for_room&.show_stats

    return standard_result.merge(battles_survived: survived(for_room).size)
                          .merge(battles_fought: battles.for_room(for_room).size)
                          .merge(total_score: for_room.total_score(self))
    # .merge(completed_at: active_battle&.completed_challenge_at(self))
  end

  def admin?
    admin
  end

  def self.valid_username?(username)
    url = "https://www.codewars.com/api/v1/users/#{username}"
    puts "Fetching data from #{url}"
    json = JSON.parse(open(url).read)
    return json["username"] == username
  rescue StandardError
    return false
  end

  def self.username_exists?(username)
    return User.where(username: username).exists?
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

  def active_battle
    room&.active_battle
  end

  def active_invite(battle = active_battle)
    battle_invites.find_by(battle: battle)
  end

  def invited?(battle = active_battle)
    return nil unless battle

    battle_invites.where(battle: battle).exists?
  end

  def confirmed?(battle = active_battle)
    return nil unless battle

    battle_invites.where(battle: battle, confirmed: true).exists?
  end

  def eligible?(battle = active_battle)
    return nil unless battle

    !completed_challenge?(battle.challenge_id) && !moderator?
  end

  def completed_challenge?(challenge_id)
    return false if challenge_id.nil?

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
    result = battles.includes(:players, players: :completed_challenges)
                    .joins(:players, players: :completed_challenges)
                    .where("battles.challenge_id = completed_challenges.challenge_id AND completed_challenges.user_id = ?", id)
                    .where("completed_challenges.completed_at > battles.start_time AND completed_challenges.completed_at < battles.end_time")

    return result unless room

    return result.includes(:room).joins(:room).where(rooms: { id: room.id })
  end

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
end
