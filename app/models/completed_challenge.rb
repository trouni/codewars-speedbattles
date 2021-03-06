# == Schema Information
#
# Table name: completed_challenges
#
#  id                  :bigint           not null, primary key
#  announced           :boolean          default(FALSE)
#  completed_at        :datetime
#  completed_languages :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  kata_id             :bigint
#  user_id             :bigint
#

class CompletedChallenge < ApplicationRecord
  belongs_to :user
  belongs_to :kata, required: false
  validates :kata_id, uniqueness: { scope: %i[user completed_at] }
  after_create_commit :update_battle

  def battle
    user.active_battle
  end

  def room
    battle&.room
  end

  def update_battle
    broadcast if should_broadcast?
    announce_completion if should_announce?
    end_battle if should_announce? && completed_by_all?
  end

  def broadcast
    room&.broadcast_active_battle
    room&.broadcast_user(user: user)
    room&.broadcast_settings(private_to_user_id: user.id)
  end
  
  def announce_completion
    if !announced?
      completed_in = time_for_speech(battle.completed_challenge_at(user) - battle.start_time)
      room.announce(
        :chat,
        "<i class='fas fa-shield-alt'></i> Challenge completed by <span class='chat-highlight'>@{#{user.name || user.username}}</span>."
      )
      room.announce(
        :voice,
        "Challenge completed by #{user.name || user.username} in #{completed_in}",
        fx: completed_by_all? ? 'countdownZero' : 'sword',
        fxPlayAt: 'start',
        fxVolume: 0.5,
        interrupt: false
      )
    end
    update(announced: true)
  end

  def end_battle
    room&.announce(
      :voice,
      "All players have completed the challenge!",
      interrupt: false
    )
    ScheduleEndBattle.perform_now(battle_id: user.active_battle.id, delay_in_seconds: 0)
  end
  
  private

  def should_broadcast?
    battle.present? && battle.kata == kata
  end
  
  def should_announce?
    battle.present? &&
    battle.ongoing? &&
    battle.kata == kata &&
    completed_at > battle.start_time
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

  def completed_by_all?
    battle.all_players_survived?
  end
end
