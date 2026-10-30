require "application_system_test_case"

class TabBlocksTest < ApplicationSystemTestCase
  test "tab staffs show as monospace blocks, not lyrics" do
    Room.instance.play(songs(:greensleeves))
    enter_guest_password

    assert_selector "#sheet-output .tab-block", count: 2
    assert_includes find("#sheet-output .tab-block", match: :first).text, "B|---1---1---|"
  end

  test "a tab wider than the phone breaks into parts that fit at a readable size" do
    Room.instance.play(songs(:greensleeves))
    enter_guest_password

    assert_selector "#sheet-output .tab-block", count: 2
    solo = find("#sheet-output .tab-block-wrap", text: "Solo").find(".tab-block")

    assert_equal 2, solo.text.scan(/^e\|/).size, solo.text
    assert evaluate_script("[...document.querySelectorAll('.tab-block')].every((el) => el.scrollWidth <= el.clientWidth + 1)")
    assert evaluate_script("[...document.querySelectorAll('.tab-block')].every((el) => parseFloat(getComputedStyle(el).fontSize) >= 14)")
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

  # Mick's call: two columns meant scrolling back up mid-song, so a song reads straight down on any screen.
  test "on a wide screen the song still reads straight down in one column" do
    # Emulated, not resized: a resized window doesn't come back to the size later tests expect.
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 1280, height: 900, deviceScaleFactor: 1, mobile: false)
    Room.instance.play(songs(:greensleeves))
    enter_guest_password

    assert_selector "#sheet-output .tab-block", count: 2

    parts = evaluate_script("[...document.querySelectorAll('#sheet-output > *')].map((el) => { const box = el.getBoundingClientRect(); return [ Math.round(box.left), Math.round(box.top) ] })")

    assert_equal 1, parts.map(&:first).uniq.size, "parts start at different lefts: #{parts.inspect}"
    assert_equal parts.map(&:last).sort, parts.map(&:last), "parts aren't in reading order: #{parts.inspect}"
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  test "every word in a lyric line sits on the same line" do
    Room.instance.play(songs(:amazing_grace))
    enter_guest_password

    assert_selector "#sheet-output .lyrics", minimum: 4

    tops = evaluate_script("[...document.querySelector('#sheet-output .row:has(.lyrics)').querySelectorAll('.lyrics')].map((el) => Math.round(el.getBoundingClientRect().top))")

    assert_equal 1, tops.uniq.size, "lyric tops differ: #{tops.inspect}"
  end

  # Seen in What's Up: a chord after the last word dropped down beside the lyrics ("OohG").
  test "a chord after the last word stays on the chord line" do
    Room.instance.play(Song.create!(title: "End chord", artist: "Traditional", written_key: "G", sheet_format: "ultimate_guitar",
      sheet: "[Interlude]\nG       Am   C             G\nOoh, Ooh Ooh"))
    enter_guest_password

    assert_selector "#sheet-output .chord", text: "Am"

    tops = evaluate_script("[...document.querySelectorAll('#sheet-output .chord')].filter((el) => el.textContent.trim()).map((el) => Math.round(el.getBoundingClientRect().top))")

    assert_equal [ 1, 4 ], [ tops.uniq.size, tops.size ], "chord tops: #{tops.inspect}"
  end

  # Seen in What's Up, Michelle and Greensleeves: a long stretch of words without a chord, or a web
  # link, ran off the right edge of the phone.
  test "long lines and links wrap on a phone instead of running off the screen" do
    Room.instance.play(Song.create!(title: "Long line", artist: "Traditional", written_key: "C", sheet_format: "chordpro",
      sheet: "I [C]scream from the top of my lungs, what's going on, and on and on and on\nhttps://en.wikipedia.org/wiki/A_page_about_a_song_(with_a_long_name)"))
    enter_guest_password

    assert_selector "#sheet-output .lyrics", text: "from the top"

    overflow = evaluate_script("[...document.querySelectorAll('#sheet-output .lyrics')].some((el) => el.getBoundingClientRect().right > document.documentElement.clientWidth)")

    assert_not overflow, "a lyric runs past the right edge of the screen"
  end
end
