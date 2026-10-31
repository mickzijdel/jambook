require "application_system_test_case"

class SongsTest < ApplicationSystemTestCase
  setup { Room.instance.play(songs(:amazing_grace)) }

  # Most songs from Buck's list have no sheet yet; a blank page looked broken.
  test "a song without a chord sheet says so, and the host can add one" do
    sign_in_as_host
    visit song_path(Song.create!(title: "No sheet yet", artist: "Traditional"))

    assert_text "No chord sheet yet"
    click_on "Add one"

    assert_field "Sheet"
  end

  test "the banner follows the room" do
    using_session(:guest) do
      enter_guest_password
      visit songs_path

      assert_text "Now playing: Amazing Grace"
      connect_turbo_cable_stream_sources
    end
    using_session(:host) do
      sign_in_as_host
      visit songs_path
      within("li.song", text: "Rising Sun") { click_on "Play" }
    end

    using_session(:guest) { assert_text "Now playing: House of the Rising Sun" }
  end

  test "a host song change brings a guest to the top of the new song" do
    using_session(:guest) do
      enter_guest_password

      assert_capo 2
      execute_script("window.scrollTo(0, 400)")
      connect_turbo_cable_stream_sources
    end
    using_session(:host) do
      sign_in_as_host
      visit songs_path
      within("li.song", text: "Rising Sun") { click_on "Play" }
    end
    using_session(:guest) do
      assert_selector "#room-key .key", text: "Am"
      assert_capo 0, shapes: "Am"
      assert_equal 0, evaluate_script("window.scrollY")
    end
  end

  test "a guest who dropped off catches up" do
    cable = "document.querySelector('turbo-cable-stream-source').subscription.consumer.connection"
    using_session(:guest) do
      enter_guest_password

      assert_capo 2
      connect_turbo_cable_stream_sources
      execute_script("#{cable}.close({ allowReconnect: false })")
    end
    using_session(:host) do
      sign_in_as_host
      visit root_path
      click_on "Key up a semitone"
    end
    using_session(:guest) do
      execute_script("#{cable}.open()")

      assert_selector "#room-key .key", text: "Bb"
    end
  end
end
