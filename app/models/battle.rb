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
  has_many :players, through: :battle_invites, class_name: "User"
  after_commit :broadcast_battle, on: %i[create update]
  after_destroy :broadcast_battle_destroyed

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
      players: players.map do |user|
        {
          user: user.api_expose,
          completed_at: user.completed_challenge(self)&.completed_at
        }
      end
    }
  end

  def results
    players.map do |user|
      {
        user: user.api_expose,
        completed_at: user.completed_challenge(self).completed_at
      }
    end
  end

  def survivors
    battle_invites.where(survived: true)
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
    CompletedChallenge.where(challenge_id: challenge_id, user: room.users).map(&:user)
  end
end
