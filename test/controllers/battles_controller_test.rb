require 'test_helper'

class BattlesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get battles_show_url
    assert_response :success
  end

end
