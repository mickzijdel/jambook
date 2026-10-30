require "application_system_test_case"

class SongsTest < ApplicationSystemTestCase
  setup { Room.instance.play(songs(:amazing_grace)) }

  test "the banner follows the room" do
    using_session(:guest) do
      enter_guest_password
      visit songs_path

      assert_text "Now playing: Amazing Grace"
    end
    using_session(:host) do
      sign_in_as_host
      visit songs_path
      within("li.song", text: "Rising Sun") { click_on "Play now" }
    end

    using_session(:guest) { assert_text "Now playing: House of the Rising Sun" }
  end

  test "a host song change brings a guest to the top of the new song" do
    using_session(:guest) do
      enter_guest_password

      assert_text "your capo 2"
      execute_script("window.scrollTo(0, 400)")
    end
    using_session(:host) do
      sign_in_as_host
      visit songs_path
      within("li.song", text: "Rising Sun") { click_on "Play now" }
    end
    using_session(:guest) do
      assert_text "Room key Am · your capo 0 · Am shapes"
      assert_equal 0, evaluate_script("window.scrollY")
    end
  end

  test "a guest who dropped off catches up" do
    cable = "document.querySelector('turbo-cable-stream-source').subscription.consumer.connection"
    using_session(:guest) do
      enter_guest_password

      assert_text "your capo 2"
      execute_script("#{cable}.close({ allowReconnect: false })")
    end
    using_session(:host) do
      sign_in_as_host
      visit root_path
      click_on "key +"
    end
    using_session(:guest) do
      execute_script("#{cable}.open()")

      assert_text "Room key Bb"
    end
  end
end
