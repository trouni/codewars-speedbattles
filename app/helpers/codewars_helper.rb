require 'open-uri'
require 'json'

module CodewarsHelper
  def check_battle_status(battle, since = DateTime.new(1990))
    CompletedChallenge.where("completed_at > ? AND challenge_id = ? AND user_id IN (?)", since, battle.challenge_id, battle.players.map(&:id))
  end

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

  def parse_kata_url(url)
    # https://www.codewars.com/kata/the-spider-and-the-fly-jumping-spider/train/ruby
    regex = %r{^(https:\/\/)?www\.codewars\.com\/kata\/(?<challenge_id_or_slug>.+)\/train\/(?<language>.+)$}
    matchdata = regex.match(url)
    return {
      challenge_id_or_slug: matchdata["challenge_id_or_slug"],
      language: matchdata["language"]
    }
  end

  def fetch_kata_info(args = {})
    json = fetch_url("https://www.codewars.com/api/v1/code-challenges/#{args[:challenge_id_or_slug]}")
    return {
      challenge_id: json["id"],
      challenge_url: json["url"],
      challenge_name: json["name"],
      challenge_language: args[:language],
      challenge_rank: json["rank"]["id"],
      challenge_description: json["description"]
    }
  end

  private

  def fetch_url(url)
    puts "Fetching data from #{url}"
    return JSON.parse(open(url).read)
  end
end
