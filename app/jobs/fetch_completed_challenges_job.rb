class FetchCompletedChallengesJob < ApplicationJob
  include CodewarsHelper
  queue_as :default

  # user_id, battle_id, all_pages
  def perform(args = {})
    args.reverse_merge!(
      battle_id: nil,
      all_pages: true
    )
    user = User.find(args[:user_id])

    # Fetching first page and retrieving number of pages
    total_pages = fetch_page(user)

    (1...total_pages).each { |page| fetch_page(user, page) } if args[:all_pages]

    user.update(last_fetched_at: DateTime.now)

    Battle.find(args[:battle_id]).broadcast_action('refresh-battle') if args[:battle_id]
  end
end
