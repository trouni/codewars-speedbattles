# == Schema Information
#
# Table name: completed_challenges
#
#  id                  :bigint           not null, primary key
#  user_id             :bigint
#  challenge_id        :string
#  challenge_name      :string
#  challenge_slug      :string
#  completed_at        :datetime
#  completed_languages :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'test_helper'

class CompletedChallengeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
