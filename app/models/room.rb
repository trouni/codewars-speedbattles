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
  has_many :battles do
    def for_challenge(challenge_id)
      where(challenge_id: challenge_id)
    end
  end
  has_many :players, through: :battles
  has_one :chat, dependent: :destroy
  has_many :messages, through: :chat
  validates :name, presence: true
  after_create :create_chat

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

  # def battles_index
  #   {
  #     active: active_battle&.api_expose,
  #     finished: finished_battles.map(&:api_expose)
  #   }
  # end

  def finished_battles
    Battle.includes(:room).joins(:room).where(room_id: id).where.not(end_time: nil).order(end_time: :desc)
    # battles.where.not(end_time: nil)
  end

  def last_battle
    finished_battles.first
  end

  # Room has no battle set up
  def at_peace?
    Battle.includes(:room).joins(:room).where(room: id, end_time: nil).size.zero?
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

  # def challenge_winner(challenge_id)
  #   battles.for_challenge(challenge_id)
  #          .includes(:players, players: :completed_challenges)
  #          .joins(:players, players: :completed_challenges)
  #          .select("users.id, DATEDIFF(completed_challenges.completed_at, battles.start_time)")
  # end

  def battles_fought(player)
    BattleInvite.includes(:player, :battle, :room).joins(:player, :battle, :room).where(
      confirmed: true,
      battles: { room_id: id },
      users: { id: player }
    )
    # Battle.joins(battle_invites: :player).where(battle_invites: { confirmed: true }, battles: { room_id: id }, users: { id: player.id })
    # player.battle_invites.where(confirmed: true)
  end

  def battles_survived(player)
    # Battle.joins(battle_invites: { player: :completed_challenges }).where(
    BattleInvite.includes(:player, :room, player: :completed_challenges).joins(:player, :room, player: :completed_challenges).where(
      "battle_invites.confirmed = true AND battles.room_id = ? AND completed_challenges.completed_at > battles.start_time AND completed_challenges.completed_at < battles.end_time AND completed_challenges.challenge_id = battles.challenge_id AND completed_challenges.user_id = ?",
      id,
      player.id
    )
  end

  def victories(player)
    finished_battles.includes(:players, players: :completed_challenges)
                    .joins(players: :completed_challenges)
                    .map(&:winner)
                    .select { |winner| winner == player }
  end

  def defeats(player)
    # Battle.joins(battle_invites: { player: :completed_challenges }).where('battle_invites.confirmed = true AND battles.room_id = ? AND users.id = ?', id, player.id).where.not(
    #   "completed_challenges.completed_at > battles.start_time OR completed_challenges.completed_at < battles.end_time OR completed_challenges.challenge_id = battles.challenge_id OR completed_challenges.user_id = ?",
    #   player.id
    # )
  end

  def total_score(player)
    finished_battles.map { |battle| battle.score(player) }.reduce(:+)
  end

  # def leaderboard
  #   (players + users).uniq.map do |user|
  #     {
  #       id: user.id,
  #       name: user.name,
  #       username: user.username,
  #       battles_fought: battles_fought(user).count,
  #       battles_survived: battles_survived(user).count,
  #       victories: victories(user).count,
  #       total_score: total_score(user)
  #     }
  #   end
  # end

  def broadcast(subchannel: "logs", payload: nil)
    ActionCable.server.broadcast(
      "room_#{id}",
      subchannel: subchannel,
      payload: payload
    )
  end

  def broadcast_to_moderator(subchannel: "logs", payload: nil)
    ActionCable.server.broadcast(
      "room_#{id}_moderator",
      subchannel: subchannel,
      payload: payload
    )
  end

  def broadcast_action(action:, data: nil)
    broadcast(subchannel: "action", payload: { action: action, data: data })
  end

  def broadcast_user(action: "add", user:)
    broadcast(subchannel: "users", payload: { action: action, user: user.api_expose(self, active_battle) })
  end

  def broadcast_users
    broadcast(
      subchannel: "users",
      payload: {
        action: "all",
        users: users.includes(:battles, :room, :completed_challenges, :battle_invites)
                    .map { |user| user.api_expose(self, active_battle) }
      }
    )
  end

  def broadcast_messages
    broadcast(
      subchannel: "chat",
      payload: {
        action: "all",
        messages: messages.includes(:user).map(&:api_expose)
      }
    )
  end

  def broadcast_room_players
    broadcast(
      subchannel: "users",
      payload: {
        action: "room-players",
        players: players.includes(:battles, :room, :completed_challenges, :battle_invites)
                    .map { |user| user.api_expose(self, active_battle) }
      }
    )
  end

  def broadcast_active_battle
    broadcast(subchannel: "battles", payload: { action: "active", battle: active_battle&.api_expose })
  end

  # def broadcast_battles
  #   broadcast(subchannel: "battles", payload: { action: "replace", battles: battles_index })
  # end

  private

  def create_chat
    Chat.create!(room: self, name: name)
  end
end
