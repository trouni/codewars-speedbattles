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
  has_many :battles, through: :battle_invites
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

  def api_expose(room: nil)
    standard_result = {
      id: id,
      invite_status: invite_status(room),
      last_fetched_at: last_fetched_at,
      name: name,
      username: username
    }
    return standard_result unless room

    return standard_result.merge stats(room)
  end

  def stats(room)
    {
      battles_fought: room.battles_fought(self).size,
      battles_survived: room.battles_survived(self).size,
      victories: room.victories(self).size,
      total_score: room.total_score(self)
    }
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

  def active_room
    RoomUser.includes(:room).joins(:room).find_by(user: self).room
  end

  def active_battle
    active_room.active_battle
  end

  # def current_battle_invite
  #   BattleInvite.includes(:battle, :player)
  #               .joins(:battle, :player)
  #               .find_by(confirmed: true, battles: { end_time: nil }, player: self)
  # end

  # def current_battle
  #   current_battle_invite&.battle
  # end

  def invited?(battle = active_battle)
    return nil unless battle

    BattleInvite.where(battle: battle, player: self).any?
  end

  def confirmed?(battle = active_battle)
    return nil unless battle

    BattleInvite.where(battle: battle, player: self, confirmed: true).any?
  end

  def eligible?(battle = active_battle)
    p battle
    return nil unless battle

    !completed_challenge?(battle.challenge_id) && !moderator? && !battle.started?
  end

  def completed_challenge?(challenge_id)
    CompletedChallenge.where(challenge_id: challenge_id, user_id: id).any?
  end

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

  # def broadcast_user_status(room)
  #   ActionCable.server.broadcast(
  #     "room_#{room.id}",
  #     api_expose
  #   )
  # end

  # def broadcast_user_unsubscribe(room)
  #   ActionCable.server.broadcast(
  #     "room_#{room.id}",
  #     api_expose.merge(unsubscribed: true)
  #   )
  # end

  def create_email
    self.email = "#{username}@me.com"
  end

  def create_email2
    update(email: "#{username}@me.com")
  end
end
