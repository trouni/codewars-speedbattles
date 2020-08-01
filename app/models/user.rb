# == Schema Information
#
# Table name: users
#
#  id                            :bigint           not null, primary key
#  admin                         :boolean          default(FALSE)
#  authentication_token          :string(30)
#  codewars_clan                 :string
#  codewars_honor                :integer
#  codewars_leaderboard_position :integer
#  codewars_overall_rank         :integer
#  codewars_overall_score        :integer
#  connected_webhook             :boolean          default(FALSE)
#  email                         :string
#  encrypted_password            :string           default(""), not null
#  last_fetched_at               :datetime
#  name                          :string
#  remember_created_at           :datetime
#  reset_password_sent_at        :datetime
#  reset_password_token          :string
#  username                      :string           default(""), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  codewars_id                   :string
#
require 'json'
require 'open-uri'

class User < ApplicationRecord
  acts_as_token_authenticatable
  has_one :room_user, required: false, dependent: :destroy
  has_one :room, through: :room_user, required: false
  has_many :rooms_as_moderator, class_name: "Room", foreign_key: 'moderator_id'
  has_many :battle_invites, foreign_key: 'player_id', dependent: :destroy
  has_many :battles, through: :battle_invites
  has_many :completed_challenges, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :async_fetch_codewars_info
  after_save :broadcast, if: :saved_change_to_profile?
  after_save :refresh_chat, if: :saved_change_to_name?

  alias_attribute :rank, :codewars_overall_rank

  has_settings do |s|
    s.key :base, defaults: {
      sfx: true,
      voice: true,
      music: true,
      connected_webhook: false,
      last_webhook_at: nil,
      hljs_lang: nil,
      low_res_theme: false,
      next_jid: Hash.new,
    }
  end

  def self.find(id)
    spectator = User.new(id: 0, username: 'spectator', name: 'Spectator', connected_webhook: true)
    id.zero? ? spectator : super
  end

  def connected_webhook?
    settings(:base).connected_webhook
  end

  def last_webhook_at
    settings(:base).last_webhook_at
  end

  def webhook_secret
    Base64.encode64({ id: id, t: authentication_token }.to_json).strip
  end

  def self.in(room)
    joins(:room_user).where(room_users: { room: room })
                     .select('users.id, users.username, users.name, users.last_fetched_at, room_users.created_at AS joined_room_at')
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

  def get_settings
    return {
      id: id,
      name: name,
      username: username,
      admin: admin,
      signed_in: id.positive?,
      sfx: settings(:base).sfx,
      voice: settings(:base).voice,
      # hljs_lang: settings(:base).hljs_lang,
      music: settings(:base).music,
      # webhook showing as connected for spectators
      connected_webhook: id.zero? || settings(:base).connected_webhook,
      last_webhook_at: settings(:base).last_webhook_at,
      webhook_secret: webhook_secret,
      low_res_theme: settings(:base).low_res_theme,
    }
  end

  def self.info(room, user_group = :current_users_and_players, user: nil)
    user_group = :single_user if user.present?
    return unless %i[single_user current_users_and_players all_users_and_players].include? user_group

    sql = <<-SQL
    WITH current_battle AS (
        SELECT b.*
        FROM battles b
        JOIN rooms r ON r.id = b.room_id
        WHERE r.id = :room_id
        ORDER BY b.created_at DESC
        LIMIT 1
    ), current_battle_invites AS (
        SELECT *
        FROM battle_invites bi
        WHERE bi.battle_id = (SELECT id FROM current_battle)
    ), single_user AS (
        SELECT *
        FROM users
        WHERE users.id = :user_id
    ), online_users AS (
        SELECT u.*
        FROM users u
        JOIN room_users ru ON ru.user_id = u.id
        WHERE ru.room_id = :room_id
    ), all_players AS (
        SELECT u.*
        FROM rooms r
        JOIN battles b ON b.room_id = r.id
        JOIN battle_invites bi ON b.id = bi.battle_id
        JOIN users u ON bi.player_id = u.id
        WHERE r.id = :room_id
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
            ) THEN true ELSE false END
        )
        FROM battles
        LIMIT 1
    ), current_battle_over AS (
        SELECT (
            CASE WHEN EXISTS (
                SELECT *
                FROM current_battle b
                WHERE b.end_time IS NOT NULL
            ) THEN true ELSE false END
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
            ) THEN true ELSE false END
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
        AND (
          (SELECT * FROM current_battle_ongoing)
          OR cc.completed_at < (SELECT end_time FROM current_battle) + INTERVAL '1 DAY'
      )
    ), completed_challenges AS (
        SELECT cc.*, b.id AS battle_id, b.start_time, b.end_time
        FROM #{user_group} u
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
        WHERE b.room_id = :room_id
        AND bi.confirmed
        AND b.end_time IS NOT NULL
    ), total_survived_battles AS (
      SELECT u.id AS user_id, COUNT(*) AS total_survived
      FROM #{user_group} u
      JOIN completed_challenges cc ON cc.user_id = u.id
      JOIN battle_invites bi ON bi.player_id = u.id
      JOIN battles b ON b.id = bi.battle_id
      WHERE (
          b.kata_id = cc.kata_id
          AND cc.completed_at BETWEEN b.start_time AND b.end_time
          AND bi.confirmed
      )
      GROUP BY u.id
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
        CASE WHEN u.id IN (SELECT id FROM online_users) THEN true ELSE false END
      ) AS online,
      ru.created_at AS joined_room_at,
      CASE
      WHEN u.id IN (SELECT id FROM survived_current_battle) THEN 'survived'
      WHEN u.id IN (SELECT id FROM defeated_current_battle) THEN 'defeated'
      WHEN u.id IN (SELECT id FROM current_players) THEN 'confirmed'
      WHEN u.id IN (SELECT id FROM invited_users) THEN 'invited'
      WHEN u.id IN (SELECT id FROM ineligible_users) OR (
        CASE WHEN u.id IN (SELECT id FROM online_users) THEN false ELSE true END
      ) THEN 'ineligible'
      ELSE 'eligible'
      END AS invite_status,
      bi.updated_at AS joined_battle_at,
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
      ) AS total_score,
      tsb.total_survived

      FROM (SELECT * FROM #{user_group}) u
      LEFT OUTER JOIN (SELECT user_id, completed_at FROM current_completed_challenges) cc ON cc.user_id = u.id
      LEFT OUTER JOIN room_users ru ON ru.user_id = u.id
      LEFT OUTER JOIN current_battle_invites bi ON bi.player_id = u.id
      LEFT OUTER JOIN total_survived_battles tsb ON tsb.user_id = u.id
      ORDER BY total_score DESC, battles_survived DESC, battles_fought DESC, battles_lost ASC, joined_room_at ASC, username ASC

    SQL

    execute_sql(sql, room_id: room.id, user_id: user&.id || 0)
  end

  def info(room)
    self.class.info(room, :single_user, user: self).first
  end

  def admin?
    admin
  end

  def self.username_exists?(username)
    return User.where(username: username).exists?
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

  def async_fetch_codewars_info
    FetchUserInfoJob.perform_later(id)
    FetchCompletedChallengesJob.perform_later(user_id: id, all_pages: true)
  end

  # def broadcast
  #   room&.broadcast_user(user: self)
  # end

  def broadcast_settings
    ActionCable.server.broadcast(
      "user_#{id}",
      subchannel: "settings",
      payload: { action: 'user', settings: get_settings },
      userId: id
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
