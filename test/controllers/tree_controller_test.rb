require "test_helper"

class TreeControllerTest < ActionDispatch::IntegrationTest
  test "should get familia" do
    get tree_familia_url
    assert_response :success
  end

  test "should get persona" do
    get tree_persona_url
    assert_response :success
  end
end
