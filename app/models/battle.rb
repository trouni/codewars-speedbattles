# == Schema Information
#
# Table name: battles
#
#  id                    :bigint           not null, primary key
#  room_id               :bigint
#  challenge_id          :string
#  challenge_url         :string
#  challenge_name        :string
#  challenge_language    :string
#  challenge_rank        :integer
#  challenge_description :text
#  max_survivors         :integer
#  time_limit            :integer
#  end_time              :datetime
#  start_time            :datetime
#  winner_id             :bigint
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class Battle < ApplicationRecord
  belongs_to :room
  belongs_to :winner, class_name: "User", optional: true
  has_many :battle_invites, dependent: :destroy
  # has_many :players, through: :battle_invites, class_name: "User"
  after_commit :broadcast_battle, on: %i[create update]
  after_destroy :broadcast_battle_destroyed

  def players
    User.joins(battle_invites: :battle).where(battle_invites: { confirmed: true }, battles: { id: id })
  end

  def broadcast_battle
    ActionCable.server.broadcast(
      "warroom_#{room.id}",
      api_expose
    )
  end

  def broadcast_battle_destroyed
    ActionCable.server.broadcast(
      "warroom_#{room.id}",
      api_expose.merge(deleted: true)
    )
  end

  def broadcast_action(action)
    ActionCable.server.broadcast(
      "warroom_#{room.id}",
      perform: action
    )
  end

  def challenge
    {
      id: challenge_id,
      name: challenge_name,
      url: challenge_url,
      language: challenge_language,
      rank: challenge_rank,
      description: challenge_description
    }
  end

  def api_expose
    {
      id: id,
      room_id: room.id,
      max_survivors: max_survivors,
      time_limit: time_limit,
      start_time: start_time,
      end_time: end_time,
      winner: winner&.api_expose,
      challenge: challenge,
      players: players.map do |player|
        player.api_expose.merge(completed_at: completed_challenge(player)&.completed_at)
      end
    }
  end

  def completed_challenge(player)
    return nil if players.exclude?(player)

    CompletedChallenge.where(
      "completed_at > ? AND challenge_id = ? AND user_id = ?",
      start_time,
      challenge_id,
      player.id
    ).order(completed_at: :asc).limit(1).first
  end

  def survived?(player)
    return nil if players.exclude?(player)

    CompletedChallenge.where(
      "completed_at > ? AND completed_at < ? AND challenge_id = ? AND user_id = ?",
      start_time,
      end_time,
      challenge_id,
      player.id
    ).limit(1).any?
  end

  def winner
    CompletedChallenge.where(
      "completed_at > ? AND completed_at < ? AND challenge_id = ? AND user_id IN (?)",
      start_time,
      end_time,
      challenge_id,
      players.pluck(:id)
    ).order(completed_at: :asc).limit(1).first&.user
  end

  def finishing_order
    players.map do |player|
      completed_challenge(player) || { user_id: player.id, completed_at: DateTime.new(9999) }
    end.sort_by(&:completed_at).pluck(:user_id)
  end

  def ranking(player)
    finishing_order.find_index(player.id) + 1 if finishing_order.find_index(player.id)
  end

  def score(player)
    return 0 unless survived?(player)

    case ranking(player)
    when 1
      3
    when 2
      2
    else
      1
    end
  end

  def survivors
    players.select { |player| survived?(player) }
  end

  def can_start?
    battle_invites.where(confirmed: true).count > 1
  end

  def invited_players
    battle_invites.map(&:player)
  end

  def unconfirmed_players
    battle_invites.where(confirmed: false).map(&:player)
  end

  def ineligible_users
    User.joins(:completed_challenges).where(completed_challenges: { challenge_id: challenge_id, user: room.users })
  end
end
