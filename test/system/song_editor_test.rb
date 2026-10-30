require "application_system_test_case"

class SongEditorTest < ApplicationSystemTestCase
  test "pasting ChordPro fills the key and capo" do
    sign_in_as_host
    visit new_song_path
    fill_in "Sheet", with: "{key: G}\n{capo: 2}\n[G]Amazing [C]grace"

    assert_field "Written capo", with: "2"
    assert_select "Written key", selected: "G"
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
    end
    using_session(:host) do
      sign_in_as_host
      visit root_path
      click_on "Edit note"
      fill_in "Notes", with: "Skip verse 2"
      click_on "Save note"

      assert_text "Skip verse 2"
    end
    using_session(:guest) { assert_text "Skip verse 2" }
  end
end
