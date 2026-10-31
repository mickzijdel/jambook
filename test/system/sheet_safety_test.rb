require "application_system_test_case"

class SheetSafetyTest < ApplicationSystemTestCase
  test "markup in a sheet shows as text" do
    Room.instance.play(Song.create!(title: "T", artist: "A", sheet: "[G]<img src=x onerror=document.body.dataset.pwned=1> la"))
    enter_guest_password

    within("#sheet-output") { assert_text "onerror=document.body.dataset.pwned=1" }
    assert_nil evaluate_script("document.body.dataset.pwned")
  end

  test "a sheet that won't parse still shows its text" do
    Room.instance.play(Song.create!(title: "T", artist: "A", sheet: "[G]la { la", written_key: "G"))
    enter_guest_password

    assert_text "la { la"
    assert_text "Key unknown"
  end

  test "section labels in an Ultimate Guitar sheet stay labels" do
    Room.instance.play(songs(:auld_lang_syne))
    enter_guest_password

    within("#sheet-output") { assert_selector ".chord", text: "G" }
    assert_no_selector "#sheet-output .chord", text: "Chorus"
  end

  # Seen in Californication: a line of words starting with A to G was read as chords and, with a key
  # change, transposed into "Bbalifornication".
  test "a line of words isn't mistaken for chords, so it isn't transposed" do
    Room.instance.play(Song.create!(title: "Words", artist: "Traditional", written_key: "G", house_key: "A", sheet_format: "ultimate_guitar",
      sheet: "Californication\nPsychic spies from China\nG       C\nTry to steal your mind's elation\nA7      Em-G7-C-B7  Gbm7-5\nLaid in the ashes"))
    enter_guest_password

    within("#sheet-output") do
      assert_selector ".chord", text: /\AD\z/
      assert_selector ".chord", text: /\AB7\z/ # a run of chords joined by dashes keeps its line as chords
      assert_selector ".lyrics", text: "Californication"
    end
    assert_no_selector "#sheet-output .chord", text: "alifornication"
  end

  test "saving an untouched Ultimate Guitar sheet keeps it" do
    sign_in_as_host
    visit edit_song_path(songs(:auld_lang_syne))
    click_on "Save"

    assert_text "Auld Lang Syne"
    assert_equal "ultimate_guitar", songs(:auld_lang_syne).reload.sheet_format
  end

  test "a pasted Ultimate Guitar sheet with section labels saves its chords" do
    sign_in_as_host
    visit new_song_path
    fill_in "Title", with: "Auld Lang Syne 2"
    fill_in "Artist", with: "Robert Burns"
    fill_in "Sheet", with: "[Chorus]\nG        C\nShould auld acquaintance be forgot"
    click_on "Save"

    assert_text "Auld Lang Syne 2"
    assert_includes Song.find_by!(title: "Auld Lang Syne 2").sheet, "[G]"
  end

  test "typing survives a refresh" do
    sign_in_as_host
    visit new_song_path
    fill_in "Title", with: "Half typed"
    refresh_and_wait

    assert_field "Title", with: "Half typed"
  end

  test "a half-written note survives a refresh" do
    Room.instance.play(songs(:amazing_grace))
    sign_in_as_host
    visit root_path
    click_on "Add note"
    fill_in "Notes", with: "Half a note"
    refresh_and_wait

    assert_field "Notes", with: "Half a note"
  end

  private
    # What a guest's phone does on waking up or on a broadcast: re-fetch and morph the page.
    def refresh_and_wait
      execute_script("addEventListener('turbo:render', () => window.morphed = true, { once: true }); Turbo.session.refresh(location.href)")
      page.document.synchronize { raise Capybara::ExpectationNotMet, "page not refreshed yet" unless evaluate_script("window.morphed") }
    end
end
