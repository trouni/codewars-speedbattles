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
  after_commit :broadcast_all
  after_create :destroy_if_invalid

  validates :start_time, uniqueness: { scope: :room }
  validates :end_time, uniqueness: { scope: :room }

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
    room.autonomous? || room.settings(:base).auto_invite
  end

  def launch(countdown)
    while countdown.positive?
      countdown -= 1
      sleep(1)
      room.broadcast_action(action: "update-countdown", data: { countdown: countdown })
    end

    room.broadcast_action(action: "launch-codewars") if countdown <= 0
  end

  def start
    return if started?

    update(start_time: Time.now)
    ScheduleEndBattle.perform_now(battle_id: id, delay_in_seconds: time_limit) if time_limit&.positive?
    uninvite_unconfirmed
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
    room.broadcast_users
    ScheduleRandomBattle.perform_now(room_id: room.id, delay_in_seconds: 60) if room.autonomous?
  end

  def broadcast_all
    return if room.inactive?
    
    room.broadcast_settings
    room.broadcast_active_battle
    # Broadcasting users to refresh invite status
    room.broadcast_users
  end

  def check_if_time_over
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
      challenge: challenge
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
    return if started? || over?

    case action
    when "confirm"
      confirm_user(user)
      auto_start_battle if room.autonomous?
    when "uninvite" then uninvite_user(user)
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
    start_time.present?
  end

  def ongoing?
    started? && !over?
  end

  def over?
    end_time.present?
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

  def confirmed_players
    # TODO: refactor to remove .map
    battle_invites.where(confirmed: true).map(&:player)
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
    return if start_time

    battle_invite = BattleInvite.find_by(battle: self, player: user)
    battle_invite&.destroy
    battle_invite.broadcast_user
  end

  def confirm_user(user)
    battle_invite = BattleInvite.find_by(battle: self, player: user)
    battle_invite.update(confirmed: true)
    # room.broadcast_user(user: user)
    battle_invite.broadcast_user
  end

  def invite_all
    users_to_invite = non_invited_users.map { |user| { player: user, battle: self } }
    if users_to_invite.any?
      BattleInvite.create(users_to_invite)
      room.broadcast_users
      # room.broadcast_active_battle
    end
  end

  def invite_survivors
    return unless room.last_battle

    room.last_battle.survivors.each do |user|
      next unless user.eligible?

      invite_user(user)
    end
  end

  def destroy_if_invalid
    destroy unless valid?
  end

  def auto_start_battle(delay: 30.seconds)
    return if started?

    if confirmed_players.count > 1
      ScheduleStartBattle.perform_now(battle_id: id, delay_in_seconds: delay.to_i)
    # else
    #   # Currently not working
    #   CancelStartBattle.perform_now(battle_id: id)
    end
  end
end
