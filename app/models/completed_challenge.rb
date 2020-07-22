# == Schema Information
#
# Table name: completed_challenges
#
#  id                  :bigint           not null, primary key
#  user_id             :bigint
#  DELETE: challenge_id        :string
#  DELETE: challenge_name      :string
#  DELETE: challenge_slug      :string
#  completed_at        :datetime
#  completed_languages :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class CompletedChallenge < ApplicationRecord
  belongs_to :user
  belongs_to :kata, required: false
  validates :challenge_id, uniqueness: { scope: %i[user completed_at] }
  validates :kata_id, uniqueness: { scope: %i[user completed_at] }
  after_create :broadcast_challenge, if: :should_broadcast?

  def broadcast_challenge
    battle = user.active_battle
    room = battle&.room
    room&.broadcast_active_battle
    room&.broadcast_user(user: user) if battle&.players&.include?(user)
    announce_completion
  end
  
  private
  
  def should_broadcast?
    battle = user.active_battle
    battle.present? &&
    battle.kata == kata &&
    battle.ongoing? &&
    completed_at > battle.start_time &&
    completed_at < (battle.end_time || Time.now)
  end

  def announce_completion
    battle = user.active_battle
    completed_in = time_for_speech(battle.completed_challenge_at(user) - battle.start_time)
    battle.room.announce(
      :chat,
      "<i class='fas fa-shield-alt'></i> Challenge completed by <span class='chat-highlight'>@{#{user.username}}</span>."
    )
    battle.room.announce(
      :voice,
      "Challenge completed by #{user.name || user.username} in #{completed_in}",
      fx: 'sword',
      fxPlayAt: 'start',
      fxVolume: 0.8,
      interrupt: false
    )
  end

  def time_for_speech(duration_in_seconds)
    minutes = (duration_in_seconds / 60).floor
    seconds = (duration_in_seconds % 60).floor
    if minutes.positive?
      sentence = ActionController::Base.helpers.pluralize(minutes, 'minute')
      sentence += " and #{ActionController::Base.helpers.pluralize(seconds, 'second')}" if seconds.positive?
    else
      sentence = ActionController::Base.helpers.pluralize(seconds, 'second')
    end
    return sentence
  end
end
