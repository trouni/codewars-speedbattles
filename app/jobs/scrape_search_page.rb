class ScrapeSearchPage < ApplicationJob
  queue_as :default
  include CodewarsHelper

  def perform(language: 'ruby', page_number: 0, last_page: 0)
    puts "Scraping search results page #{page_number} of #{last_page} for all #{language} katas..."
    scrape_search_page(language: language, page_number: page_number)
    ScrapeSearchPage.set(wait: 10.seconds).perform_later(language: language, page_number: page_number + 1, last_page: last_page) if page_number < last_page
  end
end
