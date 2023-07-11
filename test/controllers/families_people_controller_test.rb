require "test_helper"

class FamiliesPeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @families_person = families_people(:one)
  end

  test "should get index" do
    get families_people_url
    assert_response :success
  end

  test "should get new" do
    get new_families_person_url
    assert_response :success
  end

  test "should create families_person" do
    assert_difference('FamiliesPerson.count') do
      post families_people_url, params: { families_person: { family_id: @families_person.family_id, person_id: @families_person.person_id } }
    end

    assert_redirected_to families_person_url(FamiliesPerson.last)
  end

  test "should show families_person" do
    get families_person_url(@families_person)
    assert_response :success
  end

  test "should get edit" do
    get edit_families_person_url(@families_person)
    assert_response :success
  end

  test "should update families_person" do
    patch families_person_url(@families_person), params: { families_person: { family_id: @families_person.family_id, person_id: @families_person.person_id } }
    assert_redirected_to families_person_url(@families_person)
  end

  test "should destroy families_person" do
    assert_difference('FamiliesPerson.count', -1) do
      delete families_person_url(@families_person)
    end

    assert_redirected_to families_people_url
  end
end
