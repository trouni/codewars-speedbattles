class FetchCompletedChallengesJob < ApplicationJob
  include CodewarsHelper
  queue_as :default

  # user_id, battle_id, all_pages
  def perform(user_id:, all_pages: true)
    @user = User.find(user_id)
    if @user.last_fetched_at && @user.last_fetched_at > Time.now - 1.minute
      puts 'Fetched less than 1 min ago. Skipping fetch.'
      return
    end
    # @battle = Battle.find(battle_id) if battle_id
    @battle = @user.active_battle
    already_completed_battle = @user.survived?(@battle) if @battle
    # Fetching first page and retrieving number of pages
    unless @user.completed_challenge?(@battle&.kata)
      total_pages = fetch_page(@user)
      (1...total_pages).each { |page| fetch_page(@user, page) } if all_pages
    end
    announce_completion if @battle && @user.survived?(@battle) && !already_completed_battle
    @user.room&.broadcast_player(user: @user) if @battle&.players&.include?(@user)
  end

  private

  def announce_completion
    completed_in = time_for_speech(@battle.completed_challenge_at(@user) - @battle.start_time)
    @battle.room.announce(
      :chat,
      "<i class='fas fa-shield-alt'></i> Challenge completed by <span class='chat-highlight'>@{#{@user.username}}</span>."
    )
    @battle.room.announce(
      :voice,
      "Challenge completed by #{@user.name || @user.username} in #{completed_in}",
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
