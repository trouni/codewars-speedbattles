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
  after_commit :broadcast_battles, :broadcast_users

  def players
    User.joins(battle_invites: :battle).where(battle_invites: { confirmed: true }, battles: { id: id })
    # BattleInvite.includes(:users).where(confirmed: true, battle_id: id).map(&:user)
  end

  def launch(countdown)
    while countdown.positive?
      countdown -= 1
      sleep(1)
      room.broadcast_action(action: "update-countdown", data: { countdown: countdown })
    end

    room.broadcast_action(action: "launch-codewars") if countdown <= 0
  end

  def broadcast_battles
    room.broadcast_battles
  end

  def broadcast_users
    room.broadcast_users
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
      players: players.map(&:api_expose),
      results: expose_results
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

  def invitation(user: nil, action: nil)
    case action
    when "uninvite" then uninvite_user(user)
    when "confirm" then confirm_user(user)
    when "all" then invite_all
    when "survivors" then invite_survivors
    else invite_user(user)
    end
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

  def surviving_players
    players
      .joins(completed_challenges: :user)
      .select(:completed_at, :user_id)
      .where(
        "completed_challenges.completed_at > ? AND completed_challenges.completed_at < ? AND completed_challenges.challenge_id = ?",
        start_time,
        end_time,
        challenge_id
      )
      .order(:completed_at)
  end

  def defeated_players
    surviving_ids = surviving_players.map(&:user_id)
    players.reject{ |player| surviving_ids.include?(player.id) }
  end

  def expose_results
    survivors = surviving_players.map do |challenge|
      {
        user_id: challenge.user_id,
        username: User.find(challenge.user_id).username,
        completed_at: challenge.completed_at
      }
    end
    not_finished = defeated_players.map do |player|
      {
        user_id: player.id,
        username: player.username,
        completed_at: nil
      }
    end
    return {
      survivors: survivors,
      not_finished: not_finished
    }
  end

  def individual_ranking(player)
    surviving_players.find_index(player.id) + 1 if surviving_players.find_index(player.id)
  end

  def score(player)
    return 0 unless survived?(player)

    return individual_ranking(player) == 1 ? 2 : 1
  end

  def survivors
    players.select { |player| survived?(player) }
  end

  def started?
    !start_time.nil?
  end

  def over?
    !end_time.nil?
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

  private

  def invite_user(user)
    battle_invite = BattleInvite.find_or_initialize_by(battle: self, player: user)
    return unless battle_invite.player.eligible?

    battle_invite.save
    # room.broadcast_user(user: user)
  end

  def uninvite_user(user)
    battle_invite = BattleInvite.find_by(battle: self, player: user)
    battle_invite&.destroy
    # room.broadcast_user(user: user)
  end

  def confirm_user(user)
    battle_invite = BattleInvite.find_by(battle: self, player: user)
    battle_invite&.update(confirmed: !battle_invite.confirmed)
    # room.broadcast_user(user: user)
  end

  def invite_all
    room.users.each do |user|
      next unless user.eligible?

      invite_user(user)
    end
  end

  def invite_survivors
    return unless room.last_battle

    room.last_battle.survivors.each do |user|
      next unless user.eligible?

      invite_user(user)
    end
  end
end
