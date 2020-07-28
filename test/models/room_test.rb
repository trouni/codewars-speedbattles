# == Schema Information
#
# Table name: rooms
#
#  id           :bigint           not null, primary key
#  name         :string
#  private      :boolean          default(TRUE)
#  show_stats   :boolean          default(TRUE)
#  sound        :boolean          default(TRUE)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  moderator_id :bigint
#

require 'test_helper'

class RoomTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
