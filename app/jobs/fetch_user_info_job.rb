require 'json'
require 'open-uri'

class FetchUserInfoJob < ApplicationJob
  queue_as :default

  def perform(user)
    url = "https://www.codewars.com/api/v1/users/#{user.username}"
    puts "Fetching data from #{url}"
    json = JSON.parse(open(url).read)
    user.update(
      codewars_honor: json["honor"],
      codewars_clan: json["clan"],
      codewars_leaderboard_position: json["leaderboardPosition"],
      codewars_overall_rank: json["ranks"]["overall"]["rank"],
      codewars_overall_score: json["ranks"]["overall"]["score"]
    )
  end
end
