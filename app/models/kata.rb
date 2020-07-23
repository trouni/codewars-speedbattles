# == Schema Information
#
# Table name: katas
#
#  id                  :bigint           not null, primary key
#  category            :string
#  languages           :string           default([]), is an Array
#  last_scraped_at     :datetime
#  name                :string
#  other               :jsonb
#  rank                :integer
#  satisfaction_rating :integer
#  slug                :string
#  tags                :string           default([]), is an Array
#  total_attempts      :integer
#  total_completed     :integer
#  total_stars         :integer
#  total_votes         :integer
#  url                 :string
#  vote_score          :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  codewars_id         :string
#
class Kata < ApplicationRecord
  has_many :completed_challenges
  has_many :users, through: :completed_challenges
  validates :codewars_id, presence: true, uniqueness: true

  LANGS = {
    'c': 'C',
    'csharp': 'C#',
    'cpp': 'C++',
    'clojure': 'Clojure',
    'coffeescript': 'CoffeeScript',
    'crystal': 'Crystal',
    'dart': 'Dart',
    'elixir': 'Elixir',
    'fsharp': 'F#',
    'go': 'Go',
    'haskell': 'Haskell',
    'java': 'Java',
    'javascript': 'JavaScript',
    'php': 'PHP',
    'python': 'Python',
    'ruby': 'Ruby',
    'rust': 'Rust',
    'shell': 'Shell',
    'sql': 'SQL',
    'swift': 'Swift',
    'typescript': 'TypeScript'
  }

  def self.languages
    available_languages = pluck(:languages).flatten.uniq.sort
    LANGS.select { |lang, display_name| available_languages.include?(lang.to_s) }
  end

  def async_fetch_kata_info
    FetchKataInfoJob.perform_later(codewars_id)
  end
end
