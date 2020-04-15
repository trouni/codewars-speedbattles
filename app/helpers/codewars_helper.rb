require 'open-uri'
require 'nokogiri'
require 'json'

module CodewarsHelper
  def fetch_user(username: nil, id: nil)
    url = "https://www.codewars.com/api/v1/users/#{id || username}"
    json = JSON.parse(open(url).read)
    username ||= json["username"]
    user = User.find_by(username: username)
    FetchUserInfoJob.perform_later(user.id) if user
    return user
  end

  def fetch_page(user, page = 0)
    json = fetch_url("https://www.codewars.com/api/v1/users/#{user.username}/code-challenges/completed?page=#{page}")
    return 0 unless json

    if json["totalItems"] == user.completed_challenges.count
      puts "Already up-to-date."
    else
      json["data"].each do |challenge|
        kata = Kata.find_or_create_by(codewars_id: challenge['id'])
        CompletedChallenge.create(
          user: user,
          challenge_id: challenge["id"],
          challenge_slug: challenge["slug"],
          challenge_name: challenge["name"],
          completed_at: DateTime.parse(challenge["completedAt"]),
          completed_languages: challenge["completedLanguages"],
          kata: kata
        )
        puts "Added challenge '#{challenge["id"]}: #{challenge["slug"]}' to #{user.username}"
      end
    end
    user.update(last_fetched_at: Time.now)
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
  rescue OpenURI::HTTPError => e
    return nil
  rescue URI::InvalidURIError => e
    return nil
  end

  def scrape_kata_page(challenge_id)
    url = "https://www.codewars.com/kata/#{challenge_id}"
    html_file = open(url).read
    html_doc = Nokogiri::HTML(html_file)
    # Adding votes data to kata
    target_kata_info = html_doc.search('div[data-id]').first
    codewars_id = target_kata_info.attribute('data-id').value
    kata = Kata.find_or_initialize_by(codewars_id: codewars_id)
    stats = extract_satisfaction_stats(target_kata_info)
    kata.update(
      satisfaction_rating: stats[:satisfaction],
      total_votes: stats[:total_votes],
      last_scraped_at: Time.now
    )

    # Creating katas in the db from similar katas on the page
    html_doc.search('.list-item.kata').each do |html_kata|
      codewars_id =  html_kata.attribute('id').value
      name = html_kata.attribute('data-title').value
      stats = extract_satisfaction_stats(html_kata)
      kata = Kata.find_or_initialize_by(codewars_id: codewars_id)
      kata.update(
        name: name,
        satisfaction_rating: stats[:satisfaction],
        total_votes: stats[:total_votes],
        last_scraped_at: Time.now
      )
    end
  end

  private

  def extract_satisfaction_stats(html_element)
    m_data = html_element.search('.icon-moon-guage + span').text.strip.match(/(?<satisfaction_rating>.+)% of (?<total_votes>.+)/)
    return {
      satisfaction: m_data[:satisfaction_rating].to_i,
      total_votes: m_data[:total_votes].delete(',').to_i
    }
  end

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
