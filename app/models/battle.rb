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
  has_many :users, through: :room
  belongs_to :winner, class_name: "User", optional: true
  has_many :battle_invites, dependent: :destroy
  has_many :players, through: :battle_invites, class_name: "User"
  has_many :completed_challenges, through: :players
  scope :active, -> { where(end_time: nil) }
  after_commit :broadcast_active_battle, :broadcast_users

  def launch(countdown)
    while countdown.positive?
      countdown -= 1
      sleep(1)
      room.broadcast_action(action: "update-countdown", data: { countdown: countdown })
    end

    room.broadcast_action(action: "launch-codewars") if countdown <= 0
  end

  def broadcast_active_battle
    room.broadcast_active_battle
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
      challenge: challenge,
      players: players.includes(:room, :battles, :completed_challenges).map { |user| user.api_expose(room, self) }
    }
  end

  def completed_challenge(player)
    # return nil unless players.where(id: player.id).exists?

    CompletedChallenge.includes(:user).joins(:user)
                      .where(user_id: player.id, challenge_id: challenge_id)
                      .order(completed_at: :asc).limit(1).first
                      # .where(
                      #   "completed_at > ? AND challenge_id = ? AND user_id = ?",
                      #   start_time,
                      #   challenge_id,
                      #   player.id
                      # )
  end

  def completed_challenge_at(player)
    # return nil unless players.where(id: player.id).exists?

    CompletedChallenge.includes(:user).joins(:user)
                      .where(user_id: player.id, challenge_id: challenge_id)
                      .order(completed_at: :asc).limit(1).first&.completed_at
  end

  def invitation(user: nil, action: nil)
    case action
    when "uninvite" then uninvite_user(user)
    when "confirm" then confirm_user(user)
    when "all" then invite_all
    when "uninvite-unconfirmed" then uninvite_unconfirmed
    when "survivors" then invite_survivors
    else invite_user(user)
    end
  end

  # def survived?(player)
  #   return nil unless players.where(id: player.id).exists?

  #   query_end_time = end_time || DateTime.now

  #   CompletedChallenge.includes(:user).joins(:user).where(
  #     "completed_at > ? AND completed_at < ? AND completed_challenges.challenge_id = ? AND user_id = ?",
  #     start_time,
  #     query_end_time,
  #     challenge_id,
  #     player.id
  #   ).exists?
  # end

  def winner
    completed_challenges.includes(:user).joins(:user).order(completed_at: :asc).limit(1).first&.user
  end

  def winner?(player)
    completed_challenges.includes(:user).joins(:user).order(completed_at: :asc).limit(1).where(user_id: player.id).exists?
  end

  def completed_challenges
    query_end_time = end_time || DateTime.now

    CompletedChallenge
      .includes(:user)
      .joins(:user)
      .where(
        "completed_challenges.completed_at > ? AND completed_challenges.completed_at < ? AND completed_challenges.challenge_id = ?",
        start_time,
        query_end_time,
        challenge_id
      )
      .order(:completed_at)
      # .map(&:user)
  end

  def defeated_players
    surviving_ids = completed_challenges.pluck(:user_id)
    players.reject{ |player| surviving_ids.include?(player.id) }
  end

  def expose_results
    survivors = completed_challenges.map do |challenge|
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
    completed_challenges.find_index(player) + 1 if completed_challenges.find_index(player.id)
  end

  def score(player)
    return 0 unless player.survived?(self)

    return winner?(player) ? 2 : 1
  end

  def survivors
    completed_challenges.includes(:user).joins(:user).map(&:user)
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

  def eligible_users
    sql_query = <<-SQL
      users.id NOT IN (
        SELECT users.id
        FROM users
        JOIN completed_challenges
        ON users.id = completed_challenges.user_id
        WHERE challenge_id = ?
      )
    SQL
    users.includes(:completed_challenges).where(sql_query, challenge_id)
  end

  def non_invited_users
    sql_query = <<-SQL
      users.id NOT IN (
        SELECT users.id
        FROM users
        JOIN battle_invites
        ON users.id = battle_invites.player_id
        WHERE battle_id = ?
      )
    SQL
    eligible_users.includes(:battle_invites).where(sql_query, id)
  end

  def unconfirmed_players
    battle_invites.where(confirmed: false).map(&:player)
  end

  def ineligible_users
    users.joins(:completed_challenges).where("completed_challenges.challenge_id = ?", challenge_id)
    # User.joins(:completed_challenges).where(completed_challenges: { challenge_id: challenge_id, user: room.users })
  end

  def uninvite_unconfirmed
    battle_invites.where(confirmed: false).destroy_all
    room.broadcast_users
  end

  private

  def invite_user(user)
    return unless non_invited_users.where(id: user.id).exists?

    battle_invite = BattleInvite.includes(:battle, :player).joins(:battle, :player).create(battle: self, player: user)
    battle_invite.broadcast_user
  end

  def uninvite_user(user)
    battle_invite = BattleInvite.find_by(battle: self, player: user)
    battle_invite&.destroy
    battle_invite.broadcast_user
  end

  def confirm_user(user)
    battle_invite = BattleInvite.find_by(battle: self, player: user)
    battle_invite.update(confirmed: !battle_invite.confirmed)
    room.broadcast_user(user: user)
    room.broadcast_active_battle
  end

  def invite_all
    BattleInvite.create(non_invited_users.map { |user| { player: user, battle: self } })
    room.broadcast_users
    room.broadcast_active_battle
  end


  def invite_survivors
    return unless room.last_battle

    room.last_battle.survivors.each do |user|
      next unless user.eligible?

      invite_user(user)
    end
  end
end
