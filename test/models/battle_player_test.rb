# == Schema Information
#
# Table name: battle_players
#
#  id         :bigint           not null, primary key
#  battle_id  :bigint
#  player_id  :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class BattlePlayerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
