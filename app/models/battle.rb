# == Schema Information
#
# Table name: battles
#
#  id                 :bigint           not null, primary key
#  challenge_language :string
#  end_time           :datetime
#  max_survivors      :integer
#  start_time         :datetime
#  time_limit         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  kata_id            :bigint
#  room_id            :bigint
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
  after_commit :broadcast_with_users
  after_create :destroy_if_invalid
  after_destroy :auto_schedule_next_battle

  validates :start_time, uniqueness: { scope: :room }
  validates :end_time, uniqueness: { scope: :room }

  alias_method :invites, :battle_invites

  def auto_invite?
    room.autonomous? || room.settings(:base).auto_invite
  end

  def min_players
    room.min_users
  end

  def start
    return if started?

    update(start_time: Time.now)
    room.broadcast_action(action: "open-codewars")
    ScheduleEndBattle.perform_now(battle_id: id, delay_in_seconds: time_limit) if time_limit&.positive?
    uninvite_unconfirmed
    room.announce(
      :chat,
      "<i class='fas fa-rocket mt-5'></i> The battle for <span class='chat-highlight'>#{kata.name}</span> has begun."
    )
  end

  def terminate(end_at: nil)
    return if over?

    end_at ||= Time.now
    update(end_time: end_at)
    defeated_players.each(&:async_fetch_codewars_info)
    room.announce(
      :chat,
      "<i class='fas fa-peace mb-5'></i> The battle for <span class='chat-highlight'>#{kata.name}</span> is over."
    )
    room.broadcast_users
    auto_schedule_next_battle
  end

  def auto_schedule_next_battle
    ScheduleRandomBattle.perform_now(room_id: room.id, delay_in_seconds: 60) if room.auto_schedule_new_battle?
  end

  def broadcast_with_users
    return if room.inactive?

    room.broadcast_settings
    room.broadcast_active_battle
    # Broadcasting all users to refresh invite status incl. offline players
    room.broadcast_all_users
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
      min_players: min_players,
      time_limit: time_limit || 0,
      start_time: start_time,
      end_time: end_time,
      challenge: challenge,
      stage: stage
    }
  end

  def stage
    # 0 - No battle loaded / Battle Over (end_time exists)
    if end_time.present?
      0
    # 4 - Battle Ongoing (start_time exists, no end_time)
    elsif ongoing?
      4
    # 3 - Countdown (no end_time and countdown not zero)
    elsif room.next_event[:type] == 'start-battle' && room.time_until_next_event
      3
    # 2 - Can Start (no start_time, at least min_players confirmed)
    elsif !started? && confirmed_players.count >= min_players
      2
    # 1 - Loaded (no start_time, less than 2 confirmed players)
    else
      1
    end
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
      .where(completed_challenges: { kata: kata, completed_at: (start_time..query_end_time) })
      .order(:completed_at)
      # .map(&:user)
  end

  def defeated_players
    surviving_ids = completed_challenges.pluck(:user_id)
    players.reject{ |player| surviving_ids.include?(player.id) }
  end

  def survivors
    players.includes(:completed_challenges).joins(:completed_challenges)
           .where(completed_challenges: {
             kata: kata,
             completed_at: (start_time..(end_time || Time.now))
           })
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
  
  def ineligible_users
    users.includes(:completed_challenges).joins(:completed_challenges).where(completed_challenges: { kata_id: kata_id })
  end

  def eligible_users
    users.where.not(id: ineligible_users)
  end

  def confirmed_players
    players.where(battle_invites: { confirmed: true })
    # broadcasting in after_commit
  end

  def uninvite_unconfirmed
    battle_invites.where(confirmed: false).destroy_all
    room.broadcast_users
  end

  def all_players_survived?
    defeated_players.count.zero?
  end

  private

  def invite_user(user)
    return if ineligible_users.where(id: user).exists?

    battle_invite = BattleInvite.create(battle: self, player: user)
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
  end

  def invite_all
    users_to_invite = eligible_users.map { |user| { player: user, battle: self } }
    if users_to_invite.any?
      BattleInvite.create(users_to_invite)
      room.broadcast_users
    end
  end

  def invite_survivors
    return unless room.last_battle

    users_to_invite = room.last_battle.survivors
                                      .select { |u| u.eligible? }
                                      .map { |u| { player: u, battle: self } }
    if users_to_invite.any?
      BattleInvite.create(users_to_invite)
      room.broadcast_users
    end
  end

  def destroy_if_invalid
    destroy unless valid?
  end

  def auto_start_battle(delay: 20.seconds)
    return if started?

    if confirmed_players.count >= min_players
      ScheduleStartBattle.perform_now(battle_id: id, delay_in_seconds: delay.to_i)
    # else
    #   # Currently not working
    #   CancelStartBattle.perform_now(battle_id: id)
    end
  end
end
