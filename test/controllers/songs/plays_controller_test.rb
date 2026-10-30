require "test_helper"

class Songs::PlaysControllerTest < ActionDispatch::IntegrationTest
  test "guests can't play songs" do
    enter_guest_password
    post song_play_path(songs(:rising_sun))

    assert_redirected_to new_session_path
  end

  test "the host plays a song" do
    sign_in_as_host
    post song_play_path(songs(:rising_sun))

    assert_equal songs(:rising_sun), Room.instance.current_song
  end
end
