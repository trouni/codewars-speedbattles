require 'json'
require 'open-uri'

class FetchCompletedChallengesJob < ApplicationJob
  queue_as :default

  def perform(user)
    # Fetching first page and retrieving number of pages
    total_pages = fetch_page(user)

    (1...total_pages).each do |page|
      fetch_page(user, page)
    end

    user.update(last_fetched_at: DateTime.now)
  end

  private

  def fetch_page(user, page = 0)
    json = fetch_url("https://www.codewars.com/api/v1/users/#{user.username}/code-challenges/completed?page=#{page}")
    if json["totalItems"] == user.completed_challenges.count
      puts "Already up-to-date."
    else
      json["data"].each do |challenge|
        CompletedChallenge.create(
          user: User.find_by(username: user.username),
          challenge_id: challenge["id"],
          challenge_slug: challenge["slug"],
          challenge_name: challenge["name"],
          completed_at: DateTime.parse(challenge["completedAt"]),
          completed_languages: challenge["completedLanguages"]
        )
      end
    end

    return json["totalPages"]
  end

  def fetch_url(url)
    puts "Fetching data from #{url}"
    return JSON.parse(open(url).read)
  end
end
