class FetchCompletedChallengesJob < ApplicationJob
  include CodewarsHelper
  queue_as :default

  # user_id, battle_id, all_pages
  def perform(user_id:, battle_id: nil, all_pages: true)
    user = User.find(user_id)
    # Throttle fetching at once every 10 minutes unless battle_id exists
    # return unless user.last_fetched_at < DateTime.now - 10.minutes || battle_id

    if battle_id
      battle = Battle.find(battle_id)
      return if user.completed_challenge?(battle.challenge_id)
    end

    # Fetching first page and retrieving number of pages
    total_pages = fetch_page(user)

    (1...total_pages).each { |page| fetch_page(user, page) } if all_pages

    user.update(last_fetched_at: DateTime.now)

    battle.room.broadcast_user(user: user) if battle
  end
end
