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
require 'test_helper'

class KataTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
