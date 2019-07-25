require 'open-uri'
require 'json'

module CodewarsHelper
  def fetch_page(user, page = 0)
    json = fetch_url("https://www.codewars.com/api/v1/users/#{user.username}/code-challenges/completed?page=#{page}")
    return 0 unless json

    if json["totalItems"] == user.completed_challenges.count
      puts "Already up-to-date."
    else
      json["data"].each do |challenge|
        CompletedChallenge.create(
          user: user,
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

  def fetch_kata_info(challenge_id)
    json = fetch_url("https://www.codewars.com/api/v1/code-challenges/#{challenge_id}")
    return nil unless json

    return {
      challenge_id: json["id"],
      challenge_url: json["url"],
      challenge_name: json["name"],
      # challenge_language: args[:language],
      challenge_rank: json["rank"]["id"],
      challenge_description: json["description"]
    }
  end

  private

  def fetch_url(url)
    begin
      puts "Fetching data from #{url}"
      return JSON.parse(open(url).read)
    rescue OpenURI::HTTPError => e
      puts e
      return nil
    end
  end
end
