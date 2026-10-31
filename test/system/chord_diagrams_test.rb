require "application_system_test_case"

# Chord boxes follow what the sheet shows: Amazing Grace in A with capo 2 shows G, C and D shapes.
class ChordDiagramsTest < ApplicationSystemTestCase
  setup do
    Room.instance.play(songs(:amazing_grace))
    enter_guest_password

    assert_capo 2
  end

  test "the chord bar shows each chord in the song once, in the order they come" do
    assert_equal %w[G C D], bar_names
  end

  test "the chord bar follows the capo" do
    click_on "Capo down one fret"
    click_on "Capo down one fret"

    assert_capo 0

    assert_equal %w[A D E], bar_names
  end

  test "tapping a chord in the sheet shows how to play it, and other voicings" do
    find("#sheet-output .chord", text: /\AC\z/, match: :first).click

    assert_selector "#chord-card .chord-card-name", text: "C"
    assert_selector "#chord-card [role=img][aria-label='C: low E muted, A fret 3, D fret 2, G open, B fret 1, high E open']"
    click_on "Next voicing"

    assert_selector "#chord-card output", text: "2 of 4"
  end

  test "Esc closes the card, and a chord from the bar opens it with the keyboard in it" do
    within(".chord-bar") { click_on "D" }

    assert_selector "#chord-card .chord-card-name", text: "D"
    assert evaluate_script("document.getElementById('chord-card').contains(document.activeElement)")

    find("#chord-card").send_keys(:escape)

    assert_no_selector "#chord-card"
  end

  test "words the sheet shows as chords get no box, and say so when tapped" do
    Room.instance.play(Song.create!(title: "Spoken", artist: "Traditional", written_key: "G", sheet_format: "chordpro",
      sheet: "[Farquaad:]Silence, [G]then a song"))

    assert_selector "h1", text: "Spoken"
    assert_equal %w[G], bar_names

    find("#sheet-output .chord", text: "Farquaad:").click

    assert_selector "#chord-card", text: "No chord diagram"
  end

  test "a short chord bar has no expand button" do
    assert_equal %w[G C D], bar_names
    assert_no_button "Show all chords"
  end

  test "a long chord bar expands to show every chord, and stays expanded on this phone" do
    Room.instance.play(Song.create!(title: "Many chords", artist: "Traditional", written_key: "C", sheet_format: "chordpro",
      sheet: %w[C Dm Em F G Am Bdim C7 Fmaj7 G7 Am7 Dm7].map { |chord| "[#{chord}]la" }.join(" ")))

    assert_selector "h1", text: "Many chords"

    click_on "Show all chords"

    assert evaluate_script("[...document.querySelectorAll('.chord-bar-item')].every((item) => item.getBoundingClientRect().right <= document.documentElement.clientWidth)")

    visit root_path

    assert_button "Show fewer chords"
  end

  test "the chord card stays clear of the auto-scroll controls" do
    find("#sheet-output .chord", text: /\AC\z/, match: :first).click

    assert_selector "#chord-card .chord-card-name", text: "C"

    card_bottom, controls_top = evaluate_script("[ document.getElementById('chord-card').getBoundingClientRect().bottom, document.querySelector('.autoscroll').getBoundingClientRect().top ]")

    assert_operator card_bottom, :<=, controls_top
  end

  private
    def bar_names
      assert_selector ".chord-bar .chord-name", minimum: 1
      all(".chord-bar .chord-name").map(&:text)
    end
end
