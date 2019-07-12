module BattleHelper
  def parse_kata_url(url)
    # https://www.codewars.com/kata/the-spider-and-the-fly-jumping-spider/train/ruby
    regex = %r{^(https:\/\/)?www\.codewars\.com\/kata\/(?<challenge_id_or_slug>.+)\/train\/(?<language>.+)$}
    matchdata = regex.match(url)

    result =
      if matchdata
        { challenge_id_or_slug: matchdata["challenge_id_or_slug"], language: matchdata["language"] }
      else
        { challenge_id_or_slug: url, language: "ruby" }
      end

    return result
  end

  def users_who_completed_challenge(battle, since = DateTime.new(1990))
    CompletedChallenge.where(
      "completed_at > ? AND challenge_id = ? AND user_id IN (?)",
      since,
      battle.challenge_id,
      battle.room.users.map(&:id)
    )
  end

  def active_battle?
    @battle && @battle.end_time.nil?
  end

  def time_diff(start_time, end_time)
    seconds_diff = (start_time - end_time).to_i.abs

    hours = seconds_diff / 3600
    seconds_diff -= hours * 3600

    minutes = seconds_diff / 60
    seconds_diff -= minutes * 60

    seconds = seconds_diff

    return '%02d:%02d:%02d' % [hours, minutes, seconds]
  end
end
