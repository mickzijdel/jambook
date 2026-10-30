require "test_helper"

class SongsEditingTest < ActionDispatch::IntegrationTest
  test "guests can't edit songs" do
    enter_guest_password
    patch song_path(songs(:rising_sun)), params: { song: { title: "x" } }

    assert_redirected_to new_session_path
  end

  test "a pasted chords-over-lyrics sheet gets a guessed key" do
    sign_in_as_host
    post songs_path, params: { song: { title: "T", artist: "A", sheet: "D  G\nla la", sheet_format: "ultimate_guitar" } }

    assert_equal "D", Song.find_by!(title: "T").written_key
  end

  test "saving a key confirms a guessed one" do
    song = Song.create!(title: "T", artist: "A", sheet: "[D]la")
    sign_in_as_host
    patch song_path(song), params: { song: { written_key: "D" } }

    refute song.reload.key_guessed
  end

  test "the host deletes a song" do
    sign_in_as_host

    assert_difference("Song.count", -1) { delete song_path(songs(:no_key)) }
  end
end
