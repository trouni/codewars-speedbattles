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
  after_save :broadcast, if: :saved_change_to_profile?
  after_save :refresh_chat, if: :saved_change_to_name?

  scope :invited, ->(battle) { battle ? self.in(battle.room).select('battle_invites.created_at AS invited_at').joins(:battle_invites).where(battle_invites: { battle: battle }) : [] }
  scope :pending, ->(battle) { battle ? invited(battle).where(battle_invites: { confirmed: false }) : [] }
  scope :confirmed, ->(battle) { battle ? invited(battle).where(battle_invites: { confirmed: true }) : [] }

  alias_attribute :rank, :codewars_overall_rank

  has_settings do |s|
    s.key :base, defaults: { sfx: true, voice: true, music: false, connected_webhook: false, last_webhook_at: nil, hljs_lang: nil, low_res_theme: false }
  end

  def webhook_secret
    Base64.encode64({ id: id, t: authentication_token }.to_json).strip
  end

  def self.in(room)
    joins(:room_user).where(room_users: { room: room })
                     .select('users.id, users.username, users.name, users.last_fetched_at, room_users.created_at AS joined_at')
  end

  def self.ineligible(room)
    return self.in(room) unless room.active_battle

    self.in(room).select('completed_challenges.completed_at')
        .joins(:completed_challenges)
        .where(completed_challenges: { kata: room.active_battle.kata })
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
                     .where(<<-SQL, battle.kata_id)
                     completed_challenges.kata_id = ?
                     AND completed_challenges.completed_at > battles.start_time
                     AND completed_challenges.completed_at < battles.end_time
                     SQL
  end

  def self.defeated(battle)
    return [] unless battle

    confirmed(battle).where('users.id NOT IN (?)', survived(battle).pluck(:id))
  end

  def get_settings
    return {
      name: name,
      username: username,
      sfx: settings(:base).sfx,
      voice: settings(:base).voice,
      music: settings(:base).music,
      # hljs_lang: settings(:base).hljs_lang,
      connected_webhook: settings(:base).connected_webhook,
      last_webhook_at: settings(:base).last_webhook_at,
      webhook_secret: webhook_secret,
      low_res_theme: settings(:base).low_res_theme,
    }
  end

  def self.info(room, group: :current_users_and_players, user: nil)
    return unless %i[single_user online_users current_players current_users_and_players all_users_and_players].include? group

    sql = <<-SQL
    WITH current_battle AS (
        SELECT b.*
        FROM battles b
        JOIN rooms r ON r.id = b.room_id
        WHERE r.id = #{room.id}
        ORDER BY b.created_at DESC
        LIMIT 1
    ), current_battle_invites AS (
        SELECT *
        FROM battle_invites bi
        WHERE bi.battle_id = (SELECT id FROM current_battle)
    ), single_user AS (
        SELECT *
        FROM users
        WHERE users.id = #{user&.id || 0}
    ), online_users AS (
        SELECT u.*
        FROM users u
        JOIN room_users ru ON ru.user_id = u.id
        WHERE ru.room_id = #{room.id}
    ), all_players AS (
        SELECT u.*
        FROM rooms r
        JOIN battles b ON b.room_id = r.id
        JOIN battle_invites bi ON b.id = bi.battle_id
        JOIN users u ON bi.player_id = u.id
        WHERE r.id = #{room.id}
        GROUP BY u.id
    ), ineligible_users AS (
        SELECT u.*
        FROM online_users u
        JOIN completed_challenges cc ON u.id = cc.user_id
        WHERE (SELECT kata_id FROM current_battle) = cc.kata_id
        AND cc.completed_at IS NOT NULL
    ), invited_users AS (
        SELECT u.*
        FROM users u
        JOIN current_battle_invites bi ON bi.player_id = u.id
        WHERE NOT bi.confirmed
        GROUP BY u.id
    ), current_players AS (
        SELECT u.*
        FROM users u
        JOIN current_battle_invites bi ON bi.player_id = u.id
        WHERE bi.confirmed
        GROUP BY u.id
    ), current_users_and_players AS (
        SELECT * FROM current_players
        UNION
        SELECT * FROM online_users
    ), all_users_and_players AS (
        SELECT * FROM online_users
        UNION
        SELECT * FROM all_players
    ), current_battle_started AS (
        SELECT (
            CASE WHEN EXISTS (
                SELECT *
                FROM current_battle b
                WHERE b.start_time IS NOT NULL
            ) THEN TRUE ELSE FALSE END
        )
        FROM battles
        LIMIT 1
    ), current_battle_over AS (
        SELECT (
            CASE WHEN EXISTS (
                SELECT *
                FROM current_battle b
                WHERE b.end_time IS NOT NULL
            ) THEN TRUE ELSE FALSE END
        )
        FROM battles
        LIMIT 1
    ), current_battle_ongoing AS (
        SELECT (
            CASE WHEN EXISTS (
                SELECT *
                FROM current_battle b
                WHERE b.start_time IS NOT NULL
                AND b.end_time IS NULL
            ) THEN TRUE ELSE FALSE END
        )
        FROM battles
        LIMIT 1
    ), survived_current_battle AS (
        SELECT u.*, cc.completed_at
        FROM current_battle b
        JOIN battle_invites bi ON bi.battle_id = b.id
        JOIN current_players u ON bi.player_id = u.id
        JOIN completed_challenges cc ON u.id = cc.user_id
        WHERE (
            b.kata_id = cc.kata_id
            AND cc.completed_at > b.start_time
            AND (cc.completed_at < b.end_time OR (SELECT * FROM current_battle_ongoing))
        )
    ), defeated_current_battle AS (
        SELECT u.*
        FROM current_players u
        WHERE (SELECT * FROM current_battle_over)
        AND u.id NOT IN (SELECT id FROM survived_current_battle)
    ), current_completed_challenges AS (
        SELECT cc.*
        FROM current_players u
        JOIN completed_challenges cc ON u.id = cc.user_id
        WHERE (SELECT kata_id FROM current_battle) = cc.kata_id
    ), completed_challenges AS (
        SELECT cc.*, b.id AS battle_id, b.start_time, b.end_time
        FROM all_users_and_players u
        LEFT OUTER JOIN battle_invites bi ON u.id = bi.player_id
        LEFT OUTER JOIN battles b ON bi.battle_id = b.id
        LEFT OUTER JOIN completed_challenges cc ON cc.user_id = u.id
        WHERE cc.kata_id = b.kata_id
        AND cc.completed_at BETWEEN b.start_time AND b.end_time
        GROUP BY cc.id, b.id
    ), participations AS (
        SELECT bi.*, b.*, (
                CASE WHEN bi.player_id IN (
                    SELECT cc.user_id
                    FROM completed_challenges cc
                    WHERE cc.kata_id = b.kata_id
                ) THEN true ELSE false END
        ) AS survived_battle
        FROM battle_invites bi
        JOIN battles b ON bi.battle_id = b.id
        WHERE b.room_id = #{room.id}
    )

    SELECT
      u.id,
      ru.room_id,
      u.username,
      u.name,
      u.codewars_clan,
      u.codewars_honor,
      u.codewars_leaderboard_position,
      u.codewars_overall_rank,
      u.codewars_overall_score,
      u.last_fetched_at,
      (
        CASE WHEN u.id IN (SELECT id FROM online_users) THEN TRUE ELSE FALSE END
      ) AS online,
      ru.created_at AS joined_at,
      CASE
      WHEN u.id IN (SELECT id FROM survived_current_battle) THEN 'survived'
      WHEN u.id IN (SELECT id FROM defeated_current_battle) THEN 'defeated'
      WHEN u.id IN (SELECT id FROM current_players) THEN 'confirmed'
      WHEN u.id IN (SELECT id FROM invited_users) THEN 'invited'
      WHEN u.id IN (SELECT id FROM ineligible_users) THEN 'ineligible'
      ELSE 'eligible'
      END AS invite_status,
      bi.created_at AS invited_at,
      cc.completed_at,
      (
          SELECT COUNT(*)
          FROM participations p
          WHERE p.player_id = u.id
      ) AS battles_fought,
      (
          SELECT SUM(CASE WHEN p.survived_battle THEN 1 ELSE 0 END)
          FROM participations p
          WHERE p.player_id = u.id
      ) AS battles_survived,
      (
          SELECT SUM(CASE WHEN p.survived_battle THEN 0 ELSE 1 END)
          FROM participations p
          WHERE p.player_id = u.id
      ) AS battles_lost,
      (
          SELECT SUM(CASE WHEN p.survived_battle THEN 5 ELSE -1 END)
          FROM participations p
          WHERE p.player_id = u.id
      ) AS total_score
    FROM (SELECT * FROM #{user ? :single_user : group}) u
    LEFT OUTER JOIN (SELECT user_id, completed_at FROM current_completed_challenges) cc ON cc.user_id = u.id
    LEFT OUTER JOIN room_users ru ON ru.user_id = u.id
    LEFT OUTER JOIN current_battle_invites bi ON bi.player_id = u.id

    SQL

    execute_sql(sql, room_id: room.id)
  end

  def info(room)
    self.class.info(room, user: self).first
  end

  def unused_api_expose(for_room = room, battle = active_battle)
    standard_result = {
      id: id,
      username: username,
      name: name,
      codewars_clan: codewars_clan,
      codewars_honor: codewars_honor,
      codewars_leaderboard_position: codewars_leaderboard_position,
      codewars_overall_rank: codewars_overall_rank,
      codewars_overall_score: codewars_overall_score,
      last_fetched_at: last_fetched_at,
      online: !room.nil?,
      invite_status: invite_status(battle),
      status: invite_status(battle),
      invited_at: active_invite(battle)&.created_at,
      joined_at: room_user&.created_at,
      completed_at: battle&.completed_challenge_at(self)
    }

    return standard_result unless for_room&.show_stats

    survived = survived(for_room).size
    fought = battles.for_room(for_room).size

    return standard_result.merge(battles_survived: survived)
                          .merge(battles_fought: fought)
                          .merge(battles_lost: fought - survived)
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

    !completed_challenge?(battle.kata)
  end

  def completed_challenge?(kata)
    return false unless kata

    completed_challenges.where(kata: kata).exists?
  end

  def survived?(battle)
    end_time = battle&.end_time || Time.now

    completed_challenges.includes(user: :battles)
                        .joins(user: :battles)
                        .where(kata: battle&.kata)
                        .where("completed_at > ? AND completed_at < ?", battle&.start_time, end_time)
                        .exists?
  end

  def defeated?(battle)
    return battle.over? && !survived?(battle)
  end

  def survived(room = nil)
    result = battles.includes(:players, players: :completed_challenges)
                    .joins(:players, players: :completed_challenges)
                    .where("battles.kata_id = completed_challenges.kata_id AND completed_challenges.user_id = ?", id)
                    .where("completed_challenges.completed_at > battles.start_time AND completed_challenges.completed_at < battles.end_time")

    return result unless room

    return result.includes(:room).joins(:room).where(rooms: { id: room.id })
  end

  def status(battle = active_battle)
    return nil unless battle
    
    if survived?(battle)
      "survived"
    elsif defeated?(battle)
      "defeated"
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
  alias invite_status status

  def async_fetch_codewars_info
    FetchUserInfoJob.perform_later(id)
    FetchCompletedChallengesJob.perform_later(user_id: id, all_pages: true)
  end

  def broadcast
    room&.broadcast_user(user: self)
  end

  def broadcast_settings
    ActionCable.server.broadcast(
      "user_#{id}",
      subchannel: "settings",
      payload: { action: 'user', settings: get_settings }
    )
  end

  def saved_change_to_profile?
    saved_change_to_name? ||
    saved_change_to_username? ||
    saved_change_to_codewars_honor? ||
    saved_change_to_rank? ||
    saved_change_to_codewars_overall_score ||
    saved_change_to_codewars_leaderboard_position?
  end

  def refresh_chat
    room&.broadcast_messages
  end
end
