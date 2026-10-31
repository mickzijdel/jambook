require "application_system_test_case"

class LiveTest < ApplicationSystemTestCase
  setup { Room.instance.play(songs(:amazing_grace)) }

  test "a guest sees the room key in their capo's shapes" do
    enter_guest_password

    assert_selector "#room-key .key", text: "A"
    assert_capo 2, shapes: "G"
    within("#sheet-output") { assert_text "Amazing" }
  end

  test "a guest's capo changes only their view and is remembered" do
    enter_guest_password
    2.times { click_on "Capo down one fret" }

    assert_capo 0, shapes: "A"
    visit root_path

    assert_capo 0
  end

  test "a host key change reaches a guest and keeps their capo" do
    using_session(:guest) do
      enter_guest_password

      assert_capo 2
      connect_turbo_cable_stream_sources
    end
    using_session(:host) do
      sign_in_as_host
      visit root_path
      click_on "Key up a semitone"
    end

    using_session(:guest) do
      assert_selector "#room-key .key", text: "Bb"
      assert_capo 2, shapes: "Ab"
    end
  end

  test "sheet without a key shows its text" do
    Room.instance.play(songs(:no_key))
    enter_guest_password

    assert_text "Are you going to Scarborough Fair"
    assert_text "Key unknown"
  end

  test "capo works when storage is blocked" do
    enter_guest_password

    assert_capo 2
    execute_script("Object.defineProperty(window, 'localStorage', { get() { throw new Error('blocked') } })")
    click_on "Capo down one fret"

    assert_capo 1
  end

  test "with storage blocked, the capo survives moving between pages" do
    enter_guest_password

    assert_capo 2
    execute_script("Object.defineProperty(window, 'localStorage', { get() { throw new Error('blocked') } })")
    click_on "Capo down one fret"

    assert_capo 1

    execute_script("Turbo.visit('/songs')")

    assert_selector "h1", text: "Songs"
    execute_script("Turbo.visit('/')")

    assert_capo 1
  end
end
