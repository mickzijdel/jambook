require "application_system_test_case"

class SongEditorTest < ApplicationSystemTestCase
  test "pasting ChordPro fills the key and capo" do
    sign_in_as_host
    visit new_song_path
    fill_in "Sheet", with: "{key: G}\n{capo: 2}\n[G]Amazing [C]grace"

    assert_field "Written capo", with: "2"
    assert_select "Written key", selected: "G"
  end

  test "pasting an Ultimate Guitar sheet picks up its capo line" do
    sign_in_as_host
    visit new_song_path
    fill_in "Sheet", with: "Capo 4th fret\n\n[Verse 1]\nD/F#  G\nAn old man"

    assert_field "Written capo", with: "4"
  end

  test "a saved sheet is stored as ChordPro" do
    sign_in_as_host
    visit new_song_path
    fill_in "Title", with: "Amazing Grace 2"
    fill_in "Artist", with: "John Newton"
    fill_in "Sheet", with: "G  C\nAmazing grace"
    click_on "Save"

    assert_text "Amazing Grace 2"
    assert_equal "chordpro", Song.find_by!(title: "Amazing Grace 2").sheet_format
  end

  test "the host edits the note live" do
    Room.instance.play(songs(:amazing_grace))
    using_session(:guest) do
      enter_guest_password

      assert_capo 2
      connect_turbo_cable_stream_sources
    end
    using_session(:host) do
      sign_in_as_host
      visit root_path
      click_on "Add note"
      fill_in "Notes", with: "Skip verse 2"
      click_on "Save note"

      assert_text "Skip verse 2"
    end
    using_session(:guest) { assert_text "Skip verse 2" }
  end
end
