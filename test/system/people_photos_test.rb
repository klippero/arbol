require "application_system_test_case"

class PeoplePhotosTest < ApplicationSystemTestCase
  setup do
    @people_photo = people_photos(:one)
  end

  test "visiting the index" do
    visit people_photos_url
    assert_selector "h1", text: "People Photos"
  end

  test "creating a People photo" do
    visit people_photos_url
    click_on "New People Photo"

    fill_in "Person", with: @people_photo.person_id
    fill_in "Photo", with: @people_photo.photo_id
    click_on "Create People photo"

    assert_text "People photo was successfully created"
    click_on "Back"
  end

  test "updating a People photo" do
    visit people_photos_url
    click_on "Edit", match: :first

    fill_in "Person", with: @people_photo.person_id
    fill_in "Photo", with: @people_photo.photo_id
    click_on "Update People photo"

    assert_text "People photo was successfully updated"
    click_on "Back"
  end

  test "destroying a People photo" do
    visit people_photos_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "People photo was successfully destroyed"
  end
end
