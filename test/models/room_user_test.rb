# == Schema Information
#
# Table name: room_users
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  room_id    :bigint
#  user_id    :bigint
#

require 'test_helper'

class RoomUserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
