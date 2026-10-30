require "application_system_test_case"

class TabBlocksTest < ApplicationSystemTestCase
  test "tab staffs show as monospace blocks, not lyrics" do
    Room.instance.play(songs(:greensleeves))
    enter_guest_password

    assert_selector "#sheet-output .tab-block", count: 2
    assert_includes find("#sheet-output .tab-block", match: :first).text, "B|---1---1---|"
  end

  test "a tab wider than the phone shrinks to fit" do
    Room.instance.play(songs(:greensleeves))
    enter_guest_password

    assert_selector "#sheet-output .tab-block", count: 2

    assert evaluate_script("[...document.querySelectorAll('.tab-block')].every((el) => el.scrollWidth <= el.clientWidth + 1)")
  end

  test "tabs stay as written and say so when the chords move" do
    Room.instance.play(songs(:greensleeves))
    enter_guest_password
    click_on "Capo up one fret"

    assert_text "Tab as written: Am"
    assert_includes find("#sheet-output .tab-block", match: :first).text, "A|0----------|3"
  end

  test "ChordPro tab sections are tab blocks too" do
    Room.instance.play(Song.create!(title: "T", artist: "A", written_key: "G",
      sheet: "{start_of_tab}\ne|--3--|\nB|--0--|\n{end_of_tab}\n[G]la la"))
    enter_guest_password

    assert_selector "#sheet-output .tab-block", text: "e|--3--|"
  end

  test "a pasted tab survives saving as ChordPro" do
    sign_in_as_host
    visit new_song_path
    fill_in "Title", with: "Tabbed"
    fill_in "Artist", with: "Traditional"
    fill_in "Sheet", with: "[Intro]\ne|--3--|\nB|--0--|\n\n[Verse]\nG    C\nla la"
    click_on "Save"

    assert_text "Tabbed"
    assert_includes Song.find_by!(title: "Tabbed").sheet, "{start_of_tab: Intro}\ne|--3--|\nB|--0--|\n{end_of_tab}"
  end

  test "a tab keeps its section heading" do
    Room.instance.play(songs(:greensleeves))
    enter_guest_password

    assert_selector "#sheet-output .tab-block-wrap .label", text: "Solo"
    assert_selector "#sheet-output .tab-block-wrap .label", text: "Intro"
  end

  test "every word in a lyric line sits on the same line" do
    Room.instance.play(songs(:amazing_grace))
    enter_guest_password

    assert_selector "#sheet-output .lyrics", minimum: 4

    tops = evaluate_script("[...document.querySelector('#sheet-output .row:has(.lyrics)').querySelectorAll('.lyrics')].map((el) => Math.round(el.getBoundingClientRect().top))")

    assert_equal 1, tops.uniq.size, "lyric tops differ: #{tops.inspect}"
  end
end
