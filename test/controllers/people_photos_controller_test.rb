require "test_helper"

class PeoplePhotosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @people_photo = people_photos(:one)
  end

  test "should get index" do
    get people_photos_url
    assert_response :success
  end

  test "should get new" do
    get new_people_photo_url
    assert_response :success
  end

  test "should create people_photo" do
    assert_difference('PeoplePhoto.count') do
      post people_photos_url, params: { people_photo: { person_id: @people_photo.person_id, photo_id: @people_photo.photo_id } }
    end

    assert_redirected_to people_photo_url(PeoplePhoto.last)
  end

  test "should show people_photo" do
    get people_photo_url(@people_photo)
    assert_response :success
  end

  test "should get edit" do
    get edit_people_photo_url(@people_photo)
    assert_response :success
  end

  test "should update people_photo" do
    patch people_photo_url(@people_photo), params: { people_photo: { person_id: @people_photo.person_id, photo_id: @people_photo.photo_id } }
    assert_redirected_to people_photo_url(@people_photo)
  end

  test "should destroy people_photo" do
    assert_difference('PeoplePhoto.count', -1) do
      delete people_photo_url(@people_photo)
    end

    assert_redirected_to people_photos_url
  end
end
