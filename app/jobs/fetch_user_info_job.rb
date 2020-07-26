require 'json'
require 'open-uri'

class FetchUserInfoJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    if @user&.last_fetched_at && @user&.last_fetched_at > Time.now - 3.seconds
      puts 'Fetched less than 3 seconds ago. Skipping fetch.'
      return
    end
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
  rescue OpenURI::HTTPError => e
    puts e
    return nil
  end
end
