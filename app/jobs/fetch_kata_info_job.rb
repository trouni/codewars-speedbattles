require 'json'
require 'open-uri'

class FetchKataInfoJob < ApplicationJob
  queue_as :default

  def perform(challenge_id)
    challenge = JSON.parse(open("https://www.codewars.com/api/v1/code-challenges/#{challenge_id}").read)
    # Check if kata already exists. Create it if not.
    kata = Kata.find_or_initialize_by(codewars_id: challenge['id'])
    kata.update({
      name: challenge['name'],
      slug: challenge['slug'],
      category: challenge['category'],
      languages: challenge['languages'],
      url: challenge['url'],
      rank: challenge['rank']['id'],
      total_attempts: challenge['totalAttempts'],
      total_completed: challenge['totalCompleted'],
      total_stars: challenge['totalStars'],
      vote_score: challenge['voteScore'],
      tags: challenge['tags'],
      other: {
        published_at: challenge['publishedAt'],
        approved_at: challenge['approvedAt'],
        created_at: challenge['createdAt'],
        created_by: challenge['createdBy'],
        approved_by: challenge['approvedBy'],
        contributors_wanted: challenge['contributorsWanted'],
        unresolved: challenge['unresolved'],
        description: challenge['description'],
      }
    })
  rescue OpenURI::HTTPError => e
    puts e
    return nil
  end
end
