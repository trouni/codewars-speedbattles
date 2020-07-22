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

    # Fetching first page and retrieving number of pages
    total_pages = fetch_page(@user)
    (1...total_pages).each { |page| fetch_page(@user, page) } if all_pages
  end
end
