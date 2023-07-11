require "test_helper"

class AlbumControllerTest < ActionDispatch::IntegrationTest
  test "should get photos" do
    get album_photos_url
    assert_response :success
  end
end
