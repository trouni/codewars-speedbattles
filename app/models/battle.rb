# == Schema Information
#
# Table name: battles
#
#  id                    :bigint           not null, primary key
#  room_id               :bigint
#  DELETE: challenge_id          :string
#  DELETE: challenge_url         :string
#  DELETE: challenge_name        :string
#  RENAME: challenge_language    :string
#  DELETE: challenge_rank        :integer
#  DELETE: challenge_description :text
#  max_survivors         :integer
#  time_limit            :integer
#  end_time              :datetime
#  start_time            :datetime
#  DELETE: winner_id             :bigint
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class Battle < ApplicationRecord
  belongs_to :room
  belongs_to :kata
  has_many :users, through: :room
  has_many :battle_invites, dependent: :destroy
  has_many :players, through: :battle_invites, class_name: "User"
  has_many :completed_challenges, through: :players
  scope :active, -> { where(end_time: nil) }
  after_create :invite_all, if: :auto_invite?
  after_commit :broadcast_all, if: :persisted?

  def export_players
    {
      # Using 'invited' instead of pending for retro-compatibility
      invited: User.pending(self),
      confirmed: User.confirmed(self),
      survived: User.survived(self),
      defeated: User.defeated(self)
    }
  end

  def auto_invite?
    room.settings(:base).autonomous || room.settings(:base).auto_invite
  end

  def launch(countdown)
    while countdown.positive?
      countdown -= 1
      sleep(1)
      room.broadcast_action(action: "update-countdown", data: { countdown: countdown })
    end

    room.broadcast_action(action: "launch-codewars") if countdown <= 0
  end

  def start(countdown: 0)
    return if started?

    uninvite_unconfirmed
    room.announce(:chat, "<i class='fas fa-rocket mr-1'></i> The battle for <span class='chat-highlight'>#{kata.name}</span> is about to begin...")
    room.broadcast_action(action: 'start-countdown', data: { countdown: countdown })
    update(start_time: Time.now + countdown.seconds)
  end

  def terminate(end_at: nil)
    return if over?

    end_at ||= Time.now
    update(end_time: end_at)
    defeated_players.each(&:async_fetch_codewars_info)
    room.announce(
      :chat,
      "<i class='fas fa-peace'></i> The battle for <span class='chat-highlight'>#{kata.name}</span> is over."
    )
    broadcast_players
  end

  def broadcast_all
    return if room.inactive?
    
    room.broadcast_active_battle
    # Broadcasting users to refresh invite status
    room.broadcast_users
    broadcast_players
  end

  def refresh_status
    return unless ongoing? && time_limit&.positive?

    expected_end_time = start_time + time_limit.seconds
    terminate(end_at: expected_end_time) if expected_end_time < Time.now
  end

  def challenge
    {
      id: kata.codewars_id,
      url: kata.url,
      name: kata.name,
      language: challenge_language || 'ruby',
      rank: kata.rank,
      tags: kata.tags
    }
  end

  def api_expose
    {
      id: id,
      room_id: room.id,
      max_survivors: max_survivors,
      time_limit: time_limit || 0,
      start_time: start_time,
      end_time: end_time,
      challenge: challenge,
      players: players.includes(:room, :battles, :completed_challenges).map { |user| user.api_expose(room, self) }
      # players: export_players
    }
  end

  def completed_challenge(player)
    CompletedChallenge.where(user_id: player.id, kata_id: kata_id)
                      .order(completed_at: :asc).first
  end

  def completed_challenge_at(player)
    completed_challenge(player)&.completed_at
  end

  def invitation(user: nil, action: nil)
    return if started?

    case action
    when "uninvite" then uninvite_user(user)
    when "confirm" then confirm_user(user)
    when "all" then invite_all
    when "uninvite-unconfirmed" then uninvite_unconfirmed
    when "survivors" then invite_survivors
    else invite_user(user)
    end
  end
  
  def completed_challenges
    query_end_time = end_time || Time.now

    CompletedChallenge
      .includes(:user)
      .joins(:user)
      .where(
        "completed_challenges.completed_at > ? AND completed_challenges.completed_at < ? AND kata_id = ?",
        start_time,
        query_end_time,
        kata_id
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
    return 0 unless player.invited?(self)

    player.survived?(self) ? 5 : -1
  end

  def survivors
    completed_challenges.includes(:user).joins(:user).map(&:user)
  end

  def started?
    !start_time.nil?
  end

  def ongoing?
    started? && !over?
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
  
  def ineligible_users
    users.includes(:completed_challenges).joins(:completed_challenges).where(completed_challenges: { kata_id: kata_id })
  end

  def eligible_users
    users.where.not(id: ineligible_users.pluck(:id))
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

  def uninvite_unconfirmed
    battle_invites.where(confirmed: false).destroy_all
    room.broadcast_users
  end

  def broadcast_players
    room.broadcast(
      subchannel: "battles",
      payload: {
        action: "players",
        players: players.map { |user| user.api_expose(room, self) }
      }
    )
  end

  private

  def invite_user(user)
    return unless non_invited_users.where(id: user.id).exists?

    battle_invite = BattleInvite.includes(:battle, :player).joins(:battle, :player).create(battle: self, player: user)
    battle_invite.broadcast_player
  end

  def uninvite_user(user)
    return if start_time

    battle_invite = BattleInvite.find_by(battle: self, player: user)
    battle_invite&.destroy
    battle_invite.broadcast_player
  end

  def confirm_user(user)
    battle_invite = BattleInvite.find_by(battle: self, player: user)
    battle_invite.update(confirmed: true)
    # room.broadcast_user(user: user)
    battle_invite.broadcast_player
  end

  def invite_all
    BattleInvite.create(non_invited_users.map { |user| { player: user, battle: self } })
    broadcast_players
    # room.broadcast_active_battle
  end

  def invite_survivors
    return unless room.last_battle

    room.last_battle.survivors.each do |user|
      next unless user.eligible?

      invite_user(user)
    end
  end
end
