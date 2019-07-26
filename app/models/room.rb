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
  has_many :battles
  has_one :chat, dependent: :destroy
  validates :name, presence: true
  after_create :create_chat

  def active_battle
    Battle.where(room: self).find_by(end_time: nil)
  end

  def active_battle?
    active_battle.present?
  end

  def finished_battles
    battles.where.not(end_time: nil)
  end

  def last_battle
    finished_battles.order(end_time: :asc).last
  end

  # Room has no battle set up
  def at_peace?
    active_battle.nil?
  end

  # Room has an ongoing battle (started but not finished)
  def at_war?
    active_battle.present? && active_battle.start_time.present?
  end

  # Room has a pending battle (set up but not yet started)
  def brink_of_war?
    active_battle.present? && !at_war?
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

  def players
    User.joins(battle_invites: :battle).where(battle_invites: { confirmed: true }, battles: { room_id: id }).uniq
  end

  def battles_fought(player)
    Battle.joins(battle_invites: :player).where(battle_invites: { confirmed: true }, battles: { room_id: id }, users: { id: player.id })
    # player.battle_invites.where(confirmed: true)
  end

  def battles_survived(player)
    Battle.joins(battle_invites: { player: :completed_challenges }).where(
      "battle_invites.confirmed = true AND battles.room_id = ? AND completed_challenges.completed_at > battles.start_time AND completed_challenges.completed_at < battles.end_time AND completed_challenges.challenge_id = battles.challenge_id AND completed_challenges.user_id = ?",
      id,
      player.id
    )
  end

  def victories(player)
    finished_battles.map(&:winner).select { |winner| winner == player }
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

  def leaderboard
    (players + users + current_user).uniq.map do |user|
      {
        id: user.id,
        name: user.name,
        username: user.username,
        battles_fought: battles_fought(user).count,
        battles_survived: battles_survived(user).count,
        victories: victories(user).count,
        total_score: total_score(user)
      }
    end
  end

  private

  def create_chat
    Chat.create!(room: self, name: name)
  end
end
