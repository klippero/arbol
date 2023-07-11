require "test_helper"

class ArbolControllerTest < ActionDispatch::IntegrationTest
  test "should get familia" do
    get arbol_familia_url
    assert_response :success
  end
end
