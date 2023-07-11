require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = people(:one)
  end

  test "should get index" do
    get people_url
    assert_response :success
  end

  test "should get new" do
    get new_person_url
    assert_response :success
  end

  test "should create person" do
    assert_difference('Person.count') do
      post people_url, params: { person: { birthdate: @person.birthdate, birthdateAcc: @person.birthdateAcc, birthorder: @person.birthorder, birthplace: @person.birthplace, childrenof_id: @person.childrenof_id, comment: @person.comment, death: @person.death, deathAcc: @person.deathAcc, deathplace: @person.deathplace, name: @person.name, surname: @person.surname, surname2: @person.surname2 } }
    end

    assert_redirected_to person_url(Person.last)
  end

  test "should show person" do
    get person_url(@person)
    assert_response :success
  end

  test "should get edit" do
    get edit_person_url(@person)
    assert_response :success
  end

  test "should update person" do
    patch person_url(@person), params: { person: { birthdate: @person.birthdate, birthdateAcc: @person.birthdateAcc, birthorder: @person.birthorder, birthplace: @person.birthplace, childrenof_id: @person.childrenof_id, comment: @person.comment, death: @person.death, deathAcc: @person.deathAcc, deathplace: @person.deathplace, name: @person.name, surname: @person.surname, surname2: @person.surname2 } }
    assert_redirected_to person_url(@person)
  end

  test "should destroy person" do
    assert_difference('Person.count', -1) do
      delete person_url(@person)
    end

    assert_redirected_to people_url
  end
end
