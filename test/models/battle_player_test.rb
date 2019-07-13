# == Schema Information
#
# Table name: battle_invites
#
#  id         :bigint           not null, primary key
#  battle_id  :bigint
#  player_id  :bigint
#  confirmed  :boolean          default(FALSE)
#  survived   :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class BattleInviteTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
