require "application_system_test_case"

class LiveTest < ApplicationSystemTestCase
  setup { Room.instance.play(songs(:amazing_grace)) }

  test "a guest sees the room key in their capo's shapes" do
    enter_guest_password

    assert_text "Room key A · your capo 2 · G shapes"
    within("#sheet-output") { assert_text "Amazing" }
  end

  test "a guest's capo changes only their view and is remembered" do
    enter_guest_password
    2.times { click_on "capo −" }

    assert_text "Room key A · your capo 0 · A shapes"
    visit root_path

    assert_text "your capo 0"
  end

  test "a host key change reaches a guest and keeps their capo" do
    using_session(:guest) do
      enter_guest_password

      assert_text "your capo 2"
    end
    using_session(:host) do
      sign_in_as_host
      visit root_path
      click_on "key +"
    end

    using_session(:guest) { assert_text "Room key Bb · your capo 2 · Ab shapes" }
  end

  test "sheet without a key shows its text" do
    Room.instance.play(songs(:no_key))
    enter_guest_password

    assert_text "Are you going to Scarborough Fair"
    assert_text "Key unknown"
  end

  test "capo works when storage is blocked" do
    enter_guest_password

    assert_text "your capo 2"
    execute_script("Object.defineProperty(window, 'localStorage', { get() { throw new Error('blocked') } })")
    click_on "capo −"

    assert_text "your capo 1"
  end
end
