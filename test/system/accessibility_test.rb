require "application_system_test_case"

# WCAG 2.2 checks that need a rendered page.
class AccessibilityTest < ApplicationSystemTestCase
  SMALL_CONTROLS = <<~JS
    [...document.querySelectorAll("a[href], button, input:not([type=hidden]), select, textarea")]
      .map((el) => [ el, el.getBoundingClientRect() ])
      .filter(([, box]) => box.width > 0 && (box.width < 24 || box.height < 24))
      .map(([el, box]) => `${el.textContent.trim() || el.getAttribute("aria-label")} ${Math.round(box.width)}x${Math.round(box.height)}`)
  JS

  test "at 320px wide nothing needs sideways scrolling" do
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 320, height: 640, deviceScaleFactor: 1, mobile: true)
    sign_in_as_host
    Room.instance.play(songs(:greensleeves))

    [ root_path, songs_path, edit_song_path(songs(:greensleeves)) ].each do |path|
      visit path

      assert_selector "h1"

      assert evaluate_script("document.documentElement.scrollWidth <= document.documentElement.clientWidth"), "#{path} scrolls sideways at 320px"
    end
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  test "every control on the room page and the song list is at least 24px square" do
    songs(:amazing_grace).update!(notes: "Slow it down.")
    sign_in_as_host
    Room.instance.play(songs(:amazing_grace))
    visit root_path

    assert_capo 2

    assert_empty evaluate_script(SMALL_CONTROLS)

    visit songs_path

    assert_selector ".song", minimum: 2

    assert_empty evaluate_script(SMALL_CONTROLS)
  end

  test "a control that gets focus is never hidden under the pinned song header" do
    song = Song.create!(title: "A song with a title long enough to wrap", artist: "Traditional", written_key: "G", sheet_format: "chordpro",
      sheet: Array.new(60) { |i| "[G]Line #{i} of a long song" }.join("\n"))
    sign_in_as_host
    Room.instance.play(song)
    visit root_path

    assert_selector ".lyrics", text: "59 of a long song"

    # Chrome scrolls a focused control to the middle; Firefox and Safari scroll it to the nearest edge.
    execute_script("window.scrollTo(0, document.body.scrollHeight)")
    execute_script("document.querySelector('.edit-note').scrollIntoView({ block: 'nearest' })")
    note_top, head_bottom = evaluate_script("[ document.querySelector('.edit-note').getBoundingClientRect().top, document.querySelector('.song-head').getBoundingClientRect().bottom ]")

    assert_operator note_top, :>=, head_bottom, "the focused link is under the header"
  end
end
