require_relative '../../app/helpers/codewars_helper'

include CodewarsHelper

namespace :katas do
  # desc "Migrate completed challenges to katas"
  # task create_from_challenges: :environment do
  #   CompletedChallenge.all.each_with_index do |challenge, index|
  #     print "Processing challenge #{index + 1} out of #{CompletedChallenge.count}\r"
  #     $stdout.flush
  #     kata = Kata.find_or_initialize_by(codewars_id: challenge.challenge_id)
  #     kata.update({
  #       name: kata.name || challenge.challenge_name,
  #       slug: kata.slug || challenge.challenge_slug,
  #     })
  #     challenge.update(kata: kata)
  #   end
  # end

  # desc "Migrate battles to katas"
  # task create_from_battles: :environment do
  #   Battle.all.each_with_index do |battle, index|
  #     print "Processing battle #{index + 1} out of #{Battle.count}\r"
  #     $stdout.flush
  #     kata = Kata.find_or_initialize_by(codewars_id: battle.challenge_id)
  #     kata.update({
  #       name: kata.name || battle.challenge_name,
  #       url: kata.url || battle.challenge_url,
  #       rank: kata.rank || battle.challenge_rank,
  #     })
  #     battle.update(kata: kata)
  #   end
  # end

  desc "Scrape all Codewars katas"
  task :scrape_all_katas, [:language] => :environment do |task, args|
    args = { language: 'ruby' } unless args[:language]
    scrape_all_katas(**args)
  end
end
  