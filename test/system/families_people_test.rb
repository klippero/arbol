require "application_system_test_case"

class FamiliesPeopleTest < ApplicationSystemTestCase
  setup do
    @families_person = families_people(:one)
  end

  test "visiting the index" do
    visit families_people_url
    assert_selector "h1", text: "Families People"
  end

  test "creating a Families person" do
    visit families_people_url
    click_on "New Families Person"

    fill_in "Family", with: @families_person.family_id
    fill_in "Person", with: @families_person.person_id
    click_on "Create Families person"

    assert_text "Families person was successfully created"
    click_on "Back"
  end

  test "updating a Families person" do
    visit families_people_url
    click_on "Edit", match: :first

    fill_in "Family", with: @families_person.family_id
    fill_in "Person", with: @families_person.person_id
    click_on "Update Families person"

    assert_text "Families person was successfully updated"
    click_on "Back"
  end

  test "destroying a Families person" do
    visit families_people_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Families person was successfully destroyed"
  end
end
