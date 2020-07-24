# == Schema Information
#
# Table name: battles
#
#  id                 :bigint           not null, primary key
#  challenge_language :string
#  end_time           :datetime
#  max_survivors      :integer
#  start_time         :datetime
#  time_limit         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  kata_id            :bigint
#  room_id            :bigint
#

require 'test_helper'

class BattleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
