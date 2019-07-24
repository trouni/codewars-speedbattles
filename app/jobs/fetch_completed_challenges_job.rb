class FetchCompletedChallengesJob < ApplicationJob
  include CodewarsHelper
  queue_as :default

  def perform(user_id, battle_id = nil)
    user = User.find(user_id)

    # Fetching first page and retrieving number of pages
    total_pages = fetch_page(user)

    (1...total_pages).each do |page|
      fetch_page(user, page)
    end

    user.update(last_fetched_at: DateTime.now)

    Battle.find(battle_id).broadcast_action('refresh-battle') if battle_id
  end
end
