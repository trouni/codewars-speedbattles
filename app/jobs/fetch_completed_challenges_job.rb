class FetchCompletedChallengesJob < ApplicationJob
  include CodewarsHelper
  queue_as :default

  # user_id, battle_id, all_pages
  def perform(user_id:, battle_id: nil, all_pages: true)
    user = User.find(user_id)

    # Fetching first page and retrieving number of pages
    total_pages = fetch_page(user)

    (1...total_pages).each { |page| fetch_page(user, page) } if all_pages

    user.update(last_fetched_at: DateTime.now)

    Battle.find(battle_id).room.broadcast_user(user: user) if battle_id
  end
end
