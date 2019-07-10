# == Schema Information
#
# Table name: battles
#
#  id              :bigint           not null, primary key
#  room_id         :bigint
#  challenge_id    :string
#  sudden_death    :boolean
#  max_survivors :integer
#  time_limit      :integer
#  archived        :boolean
#  start_time      :datetime
#  winner_id       :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'test_helper'

class BattleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
