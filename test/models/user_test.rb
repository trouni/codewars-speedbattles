# == Schema Information
#
# Table name: users
#
#  id                            :bigint           not null, primary key
#  admin                         :boolean          default(FALSE)
#  authentication_token          :string(30)
#  codewars_clan                 :string
#  codewars_honor                :integer
#  codewars_leaderboard_position :integer
#  codewars_overall_rank         :integer
#  codewars_overall_score        :integer
#  connected_webhook             :boolean          default(FALSE)
#  email                         :string
#  encrypted_password            :string           default(""), not null
#  last_fetched_at               :datetime
#  name                          :string
#  remember_created_at           :datetime
#  reset_password_sent_at        :datetime
#  reset_password_token          :string
#  username                      :string           default(""), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  codewars_id                   :string
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
