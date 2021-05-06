# == Schema Information
#
# Table name: completed_challenges
#
#  id                  :bigint           not null, primary key
#  announced           :boolean          default(FALSE)
#  completed_at        :datetime
#  completed_languages :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  kata_id             :bigint
#  user_id             :bigint
#

require 'test_helper'

class CompletedChallengeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
