# == Schema Information
#
# Table name: rooms
#
#  id           :bigint           not null, primary key
#  name         :string
#  moderator_id :bigint
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Room < ApplicationRecord
  belongs_to :moderator, class_name: "User"
  has_many :room_users, dependent: :destroy
  has_many :users, through: :room_users
  has_many :battles, dependent: :destroy
  has_many :players, through: :battles
  has_one :chat, dependent: :destroy
  has_many :messages, through: :chat
  validates :name, presence: true

  after_create :create_chat
  after_update :announce_new_name, if: :saved_change_to_name?

  has_settings do |s|
    s.key :base, defaults: {
      sound: true,
      classification: 'TOP SECRET',
      katas: {
        ranks: [-8, -7, -6, -5, -4, -3, -2, -1],
        min_votes: 50,
        min_satisfaction: 90,
        ignore_higher_rank_users: false,
      },
      languages: ['ruby'],
      auto_invite: false,
      auto_start: false,
      voice_chat_url: nil,
      # Array of languages for future support of multi-lang rooms
      moderators: []
    }
  end

  def settings_hash
    return {
      name: name,
      sound: settings(:base).sound,
      voice_chat_url: settings(:base).voice_chat_url,
      classification: settings(:base).classification,
      katas: settings(:base).katas,
      codewars_langs: Kata.languages,
      languages: settings(:base).languages,
    }
  end

  def inactive?
    room_users.empty?
  end

  def players
    super.distinct
    # User.joins(battle_invites: :battle).where(battle_invites: { confirmed: true }, battles: { room_id: id }).uniq
  end

  def active_battle
    active_battle = Battle.includes(:room).joins(:room).find_by(room: self, end_time: nil)
    return active_battle || last_battle
  end

  def active_battle?
    active_battle.present?
  end

  def finished_battles
    Battle.includes(:room).joins(:room).where(room_id: id).where.not(end_time: nil).order(end_time: :desc)
    # battles.where.not(end_time: nil)
  end

  def last_battle
    finished_battles.first
  end

  # Room has no battle set up
  def at_peace?
    !Battle.includes(:room).joins(:room).where(room: id, end_time: nil).exists?
  end

  # Room has an ongoing battle (started but not finished)
  def at_war?
    active_battle.present? && active_battle.start_time.present?
  end

  # Room has a pending battle (set up but not yet started)
  def brink_of_war?
    Battle.includes(:room).joins(:room).where(room: self, end_time: nil).where.not(start_time: nil).present?
  end

  def battle_status
    if at_peace?
      "at_peace"
    elsif brink_of_war?
      "brink_of_war"
    elsif at_war?
      "at_war"
    end
  end

  def leaderboard
    query_fought = <<-SQL
    SELECT COUNT(*) AS battles_fought, u.id AS id, u.username AS username, u.name AS name, u.codewars_honor, u.codewars_clan, u.codewars_leaderboard_position, u.codewars_overall_rank, u.codewars_overall_score
    FROM battles b
    JOIN battle_invites bi ON b.id = bi.battle_id
    JOIN users u ON bi.player_id = u.id
    WHERE bi.confirmed = true
    AND b.room_id = #{id}
    AND b.end_time IS NOT NULL
    GROUP BY u.id
    SQL

    query_survived = <<-SQL
    SELECT COUNT(*) AS battles_survived, u.id AS id
    FROM battles b
    JOIN battle_invites bi ON b.id = bi.battle_id
    JOIN users u ON bi.player_id = u.id
    LEFT JOIN completed_challenges cc ON cc.user_id = u.id
    WHERE bi.confirmed = true
    AND b.room_id = #{id}
    AND cc.completed_at > b.start_time
    AND cc.completed_at < b.end_time
    AND cc.kata_id = b.kata_id
    GROUP BY u.id
    SQL

    query = <<-SQL
    SELECT FirstQuery.id, FirstQuery.username, FirstQuery.name, FirstQuery.codewars_honor, FirstQuery.battles_fought AS battles_fought, COALESCE(SecondQuery.battles_survived, 0) AS battles_survived, (COALESCE(FirstQuery.battles_fought, 0) - COALESCE(SecondQuery.battles_survived, 0)) AS battles_lost, (COALESCE(SecondQuery.battles_survived, 0) * 5) - (COALESCE(FirstQuery.battles_fought, 0) - COALESCE(SecondQuery.battles_survived, 0)) AS total_score
    FROM (#{query_fought}) AS FirstQuery
    LEFT JOIN (#{query_survived}) AS SecondQuery ON FirstQuery.id = SecondQuery.id
    ORDER BY total_score DESC
    SQL

    leaderboard = {}
    ActiveRecord::Base.connection.exec_query(query).as_json.each { |e| leaderboard[e["id"].to_s] = e }
    return leaderboard
    # return ActiveRecord::Base.connection.exec_query(query).as_json
  end

  def battles_fought(player)
    BattleInvite.includes(:player, :battle, :room).joins(:player, :battle, :room).where(
      confirmed: true,
      battles: { room_id: id },
      users: { id: player }
    )
  end

  def battles_survived(player)
    # Battle.joins(battle_invites: { player: :completed_challenges }).where(
    BattleInvite.includes(:player, :room, player: :completed_challenges).joins(:player, :room, player: :completed_challenges).where(
      "battle_invites.confirmed = true AND battles.room_id = ? AND completed_challenges.completed_at > battles.start_time AND completed_challenges.completed_at < battles.end_time AND completed_challenges.kata_id = battles.kata_id AND completed_challenges.user_id = ?",
      id,
      player.id
    )
  end

  def total_score(player)
    finished_battles.map { |battle| battle.score(player) }.reduce(:+)
  end

  def available_katas(language: nil, ranks: [], min_votes: nil, min_satisfaction: nil, ignore_higher_rank_users: true, excluded_users: [])
    selected_users = users.reject { |user| excluded_users.include?(user) }
    selected_users.reject! { |user| user.rank > ranks.max } if ignore_higher_rank_users && ranks.any?
    selection = Kata.where.not(id: Kata.joins(:users).where(users: { id: selected_users }).distinct)
    selection = selection.where.not(satisfaction_rating: nil)
    selection = selection.where('total_votes > ?', min_votes) if min_votes
    selection = selection.where('satisfaction_rating > ?', min_satisfaction) if min_satisfaction
    selection = selection.where(rank: ranks) if ranks.any?
    selection = selection.where("? = ANY (languages)", language) if language
    selection.order(satisfaction_rating: :desc)
  end

  def random_kata(**options)
    available_katas(options).sample
  end

  def broadcast(subchannel: "logs", payload: nil, private_to_user_id: nil)
    return if inactive?

    ActionCable.server.broadcast(
      private_to_user_id ? "user_#{private_to_user_id}" : "room_#{id}",
      subchannel: subchannel,
      payload: payload
    )
  end

  def broadcast_settings(private_to_user_id: nil)
    broadcast({
      subchannel: "settings",
      payload: {
        action: "room",
        settings: settings_hash
      },
      private_to_user_id: private_to_user_id
    })
  end

  def broadcast_to_moderator(subchannel: "logs", payload: nil)
    return if inactive? || !moderator

    ActionCable.server.broadcast(
      "user_#{moderator.id}",
      subchannel: subchannel,
      payload: payload
    )
  end

  def broadcast_users(private_to_user_id: nil)
    broadcast(
      subchannel: "users",
      payload: {
        action: "all",
        users: users.includes(:battles, :room, :completed_challenges, :battle_invites)
                    .map { |user| user.api_expose(self, active_battle) }
      },
      private_to_user_id: private_to_user_id
    )
  end

  def new_broadcast_users
    broadcast(
      subchannel: "users",
      payload: {
        action: "users",
        users: export_users
      }
    )
  end

  def export_users
    {
      eligible: User.eligible(self),
      ineligible: User.ineligible(self)
    }
  end

  def self.retrofit(hash)
    return hash.map do |status, users|
      return [] unless users

      users.map { |user| user.attributes.merge("invite_status" => status.to_s).symbolize_keys }
    end.flatten
  end

  def announce(channel, message, **options)
    case channel
    when :chat then chat.create_announcement(message)
    when :voice then broadcast_voice(message, options)
    end
  end

  def broadcast_voice(message, options)
    broadcast(
      subchannel: "action",
      payload: {
        action: "voice-announce",
        message: message,
        options: options,
      }
    )
    chat.create_announcement(message) if options[:chat_msg]
  end

  def broadcast_messages(private_to_user_id: nil)
    broadcast(
      subchannel: "chat",
      payload: {
        action: "all",
        messages: messages.includes(:user).order(created_at: :desc).limit(100).map(&:api_expose),
        authors: chat.users.select(:id, :username, :name)
      },
      private_to_user_id: private_to_user_id
    )
  end

  def broadcast_players(private_to_user_id: nil)
    broadcast(
      subchannel: "users",
      payload: {
        action: "room-players",
        players: players.includes(:battles, :room, :completed_challenges, :battle_invites)
                    .map { |user| user.api_expose(self, active_battle) }
      },
      private_to_user_id: private_to_user_id
    )
  end

  def new_broadcast_players(private_to_user_id: nil)
    broadcast(
      subchannel: "users",
      payload: {
        action: "players",
        players: export_players
      },
      private_to_user_id: private_to_user_id
    )
  end

  # def broadcast_leaderboard(private_to_user_id: nil)
  #   broadcast(
  #     subchannel: "leaderboard",
  #     payload: {
  #       action: "update",
  #       leaderboard: leaderboard
  #     },
  #     private_to_user_id: private_to_user_id
  #   )
  # end

  def broadcast_action(action:, data: nil)
    broadcast(subchannel: "action", payload: { action: action, data: data })
  end

  def broadcast_user(action: "add", user:)
    broadcast(subchannel: "users", payload: { action: action, user: user.api_expose(self, active_battle) })
  end

  def broadcast_active_battle(private_to_user_id: nil)
    active_battle&.refresh_status
    broadcast(subchannel: "battles", payload: { action: "active", battle: active_battle&.api_expose }, private_to_user_id: private_to_user_id)
  end

  def broadcast_player(action: "player", user:)
    broadcast_user(user: user)
    broadcast(subchannel: "battles", payload: { action: action, user: user.api_expose(self, active_battle) })
  end

  private

  def create_chat
    Chat.create!(room: self, name: name)
  end

  def announce_new_name
    announce(:chat, "War room renamed to <strong>#{name}</strong>.")
  end
end
