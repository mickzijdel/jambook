require "test_helper"

class SongsControllerTest < ActionDispatch::IntegrationTest
  test "search matches title or artist" do
    enter_guest_password
    get songs_path(q: "grace")

    assert_select "li.song", 1
  end

  test "the status filter shows only that status" do
    enter_guest_password
    get songs_path(status: "maybe")

    assert_select "li.song", text: /Amazing Grace/, count: 0
  end

  test "the tag filter shows only tagged songs" do
    enter_guest_password
    get songs_path(tag: "hymn")

    assert_select "li.song", 1
  end

  test "a song page shows the sheet in the song's own key" do
    enter_guest_password
    get song_path(songs(:amazing_grace))

    assert_select "#sheet[data-chord-sheet-key-value=?]", "A"
  end

  test "strangers can't see the song list" do
    get songs_path

    assert_redirected_to new_guest_access_path
  end
end
